defmodule Gitsudo.Events.AsyncWorker do
  @moduledoc """
  The AsyncWorker GenServer is responsible for handling asynchronous events.
  """
  alias Gitsudo.Workflows

  use GenServer

  require Logger

  @spec start_link(any) :: {:error, any} | {:ok, pid}
  def start_link(_) do
    GenServer.start_link(__MODULE__, {}, name: __MODULE__)
  end

  @impl true
  @spec init(any) :: {:ok, any}
  def init(init_arg) do
    {:ok, init_arg}
  end

  @impl true
  @doc """
  Handle the :app_installation_created event specifically.
  """
  def handle_cast({:app_installation_created, data}, state) do
    handle_app_installation_created(data)

    {:noreply, state}
  end

  def handle_cast({event_name, data}, state) do
    Logger.debug("handle_cast({:#{event_name}, #{inspect(data)}}, state)")

    case data do
      %{
        "installation" => %{
          "id" => installation_id
        },
        "repository" => %{
          "owner" => %{"login" => owner},
          "name" => repo
        }
      } ->
        case GitHub.TokenCache.get_or_refresh_token(installation_id) do
          {:ok, access_token} ->
            apply(__MODULE__, :"handle_#{event_name}", [access_token, owner, repo, data])

          {:error, reason} ->
            Logger.error(reason)
        end

      _ ->
        Logger.error("No \"installation\" found in #{inspect(data)}, don't know what to do!")
    end

    {:noreply, state}
  end

  @doc """
  Actually handle the app_installation_created event.
  """
  @spec handle_app_installation_created(any) :: any
  def handle_app_installation_created(%{
        "installation" =>
          %{
            "account" => %{"login" => owner}
          } = installation
      }) do
    Logger.debug("handle_app_installation_created(#{inspect(installation)})")

    with {:ok, app_installation} <- Gitsudo.GitHub.create_app_installation(installation) do
      case GitHub.TokenCache.get_or_refresh_token(app_installation.id) do
        {:ok, access_token} ->
          case GitHub.Client.list_org_repos(access_token, owner) do
            {:ok, repos} ->
              Logger.debug("Found #{length(repos)} repos under #{owner}")
              Enum.each(repos, &{create_repository(access_token, owner, &1)})

            {:error, reason} ->
              Logger.error(reason)
          end

        {:error, reason} ->
          Logger.error(reason)
      end
    end
  end

  def create_repository(access_token, owner, repo_data) do
    repository = Gitsudo.Repositories.find_or_create_repository(repo_data)
    Logger.debug("repository: #{inspect(repository)}")

    with {:ok, %{"total_count" => total_count, "workflows" => workflows}} <-
           GitHub.Client.list_workflows(access_token, owner, repository.name) do
      Logger.debug(~s'Found #{total_count} workflows for "#{owner}/#{repository.name}"')

      for workflow <- workflows do
        Logger.debug("workflow: #{inspect(workflow)}")

        with {:ok, workflow} <- Workflows.create_workflow(repository.id, workflow) do
          Logger.debug("Created workflow: #{inspect(workflow)}")
        end
      end
    end

    with {:ok, %{"total_count" => total_count, "workflow_runs" => workflow_runs} = _data} <-
           GitHub.Client.list_workflow_runs(access_token, owner, repository.name) do
      Logger.debug(~s'Found #{total_count} workflow runs for "#{owner}/#{repository.name}"')

      for workflow_run <- workflow_runs do
        Logger.debug("workflow_run: #{inspect(workflow_run)}")

        with {:ok, workflow_run} <- Workflows.create_workflow_run(workflow_run) do
          Logger.debug("Created workflow_run: #{inspect(workflow_run)}")
        end
      end

      {:ok, repository}
    end
  end

  @spec handle_workflow_job_completed(
          access_token :: String.t(),
          owner :: String.t(),
          repo :: String.t(),
          any
        ) :: any
  def handle_workflow_job_completed(
        access_token,
        owner,
        repo,
        %{"workflow_job" => %{"id" => workflow_run_id} = workflow_run} = _params
      ) do
    Logger.debug("handle_workflow_job_completed(#{inspect(workflow_run)})")

    case GitHub.Client.get_workflow_run(access_token, owner, repo, workflow_run_id) do
      {:ok, workflow_run} ->
        Gitsudo.Workflows.create_workflow_run(workflow_run)

      {:error, reason} ->
        Logger.error(reason)
    end
  end
end

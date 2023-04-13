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

  @doc """
  Create and store a Gitsudo.Repositories.Repository record for the given `repo_data` (fetched using
  GitHub.Client.list_org_repos/2).

  Then, fetches and stores all workflows and workflow runs for the given repository.
  """
  @spec create_repository(access_token :: String.t(), owner :: String.t(), repo_data :: map()) ::
          :ok
  def create_repository(access_token, owner, repo_data) do
    case Gitsudo.Repositories.find_or_create_repository(repo_data) do
      {:ok, repository} ->
        Logger.debug("repository: #{inspect(repository)}")

        fetch_and_store_all_workflows(access_token, owner, repository)

        case GitHub.Client.with_all_workflow_runs(
               access_token,
               owner,
               repository.name,
               {:ok, []},
               &with_each_workflow_run_page/2
             ) do
          {:ok, all_workflow_runs} ->
            Logger.debug(
              "Fetched and stored a total of #{length(all_workflow_runs)} workflow_runs"
            )

          {:error, reason} ->
            Logger.error(reason)
        end

      {:error, reason} ->
        Logger.error(reason)
    end
  end

  @spec with_each_workflow_run_page(map(), {:ok, list(map())} | {:error, any}) ::
          {:cont, {:ok, list(map())}} | {:halt, {:error, any}}
  defp with_each_workflow_run_page(_, {:error, reason}), do: {:halt, {:error, reason}}

  defp with_each_workflow_run_page(page, {:ok, results}) do
    case Enum.reduce_while(page["workflow_runs"], {:ok, []}, &with_each_workflow_run/2) do
      {:ok, workflow_runs} ->
        {:cont, {:ok, results ++ Enum.reverse(workflow_runs)}}

      {:error, reason} ->
        {:halt, {:error, reason}}
    end
  end

  @spec with_each_workflow_run(map(), {:ok, list(map())} | {:error, any}) ::
          {:cont, {:ok, list(map())}} | {:halt, {:error, any}}
  defp with_each_workflow_run(_, {:error, reason}), do: {:halt, {:error, reason}}

  defp with_each_workflow_run(workflow_run, {:ok, results}) do
    case Gitsudo.Workflows.create_workflow_run(workflow_run) do
      {:ok, created} ->
        Logger.debug("Created workflow_run: #{inspect(created)}")
        {:cont, {:ok, [workflow_run | results]}}

      {:error, reason} ->
        Logger.error(reason)
        {:halt, {:error, reason}}
    end
  end

  defp fetch_and_store_all_workflows(access_token, owner, repository) do
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
  end

  @spec handle_workflow_run_completed(
          access_token :: String.t(),
          owner :: String.t(),
          repo :: String.t(),
          any
        ) :: any
  def handle_workflow_run_completed(
        access_token,
        owner,
        repo,
        %{
          "workflow" => %{"id" => workflow_id},
          "workflow_run" => %{"id" => workflow_run_id} = workflow_run
        } = _params
      ) do
    Logger.debug("handle_workflow_run_completed(#{inspect(workflow_run)})")

    case GitHub.Client.get_workflow_run(access_token, owner, repo, workflow_run_id) do
      {:ok, workflow_run} ->
        workflow_run
        |> Map.put("workflow_id", workflow_id)
        |> Gitsudo.Workflows.create_workflow_run()

      {:error, reason} ->
        Logger.error(reason)
    end
  end
end

defmodule Gitsudo.Events.AsyncWorker do
  @moduledoc """
  The AsyncWorker GenServer is responsible for handling asynchronous events.
  """

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
  def handle_cast({event_name, data}, state) do
    Logger.debug("handle_cast({:#{event_name}, #{inspect(data)}}, state)")
    apply(__MODULE__, :"handle_#{event_name}", [data])

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

    case Gitsudo.GitHub.create_app_installation(installation) do
      {:ok, app_installation} ->
        Logger.debug("app_installation: #{inspect(app_installation)}")

        case GitHub.TokenCache.get_or_refresh_token(app_installation.id) do
          {:ok, access_token} ->
            Logger.debug("token: #{inspect(access_token)}")

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

      {:error, reason} ->
        Logger.error(reason)
    end
  end

  def create_repository(access_token, owner, repo_data) do
    repository = Gitsudo.Repositories.find_or_create_repository(repo_data)
    Logger.debug("repository: #{inspect(repository)}")

    with {:ok, %{"total_count" => total_count, "workflow_runs" => workflow_runs} = _data} <-
           GitHub.Client.list_workflow_runs(access_token, owner, repository.name) do
      Logger.debug(~s'Found #{total_count} workflow runs for "#{owner}/#{repository.name}"')

      for workflow_run <- workflow_runs do
        Logger.debug("workflow_run: #{inspect(workflow_run)}")
      end

      {:ok, repository}
    end
  end
end

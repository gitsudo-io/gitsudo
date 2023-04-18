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

            fetch_and_store_all_workflow_run_jobs(
              access_token,
              owner,
              repository,
              all_workflow_runs
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
    case Workflows.create_workflow_run(workflow_run) do
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

      for workflow_data <- workflows do
        Logger.debug("workflow: #{inspect(workflow_data)}")

        with {:ok, workflow} <- Workflows.create_workflow(repository.id, workflow_data) do
          Logger.debug("Created workflow: #{inspect(workflow)}")
        end
      end
    end
  end

  defp fetch_and_store_all_workflow_run_jobs(access_token, owner, repository, all_workflow_runs) do
    for workflow_run <- all_workflow_runs do
      Logger.debug("workflow_run: #{inspect(workflow_run)}")

      with {:ok, %{"total_count" => total_count, "jobs" => workflow_jobs}} <-
             GitHub.Client.list_workflow_run_jobs(
               access_token,
               owner,
               repository.name,
               workflow_run["id"]
             ) do
        Logger.debug(
          ~s'Found #{total_count} workflow_jobs for workflow_run "#{workflow_run["id"]}"'
        )

        for workflow_job_data <- workflow_jobs do
          Logger.debug("workflow_job: #{inspect(workflow_job_data)}")

          with {:ok, workflow_job} <-
                 Workflows.create_workflow_job(workflow_run["id"], workflow_job_data) do
            Logger.debug("Created workflow_job: #{inspect(workflow_job)}")
            store_workflow_job_steps(workflow_job_data)
          end
        end
      end
    end
  end

  @doc """
  Actually handle the workflow_run_in_progress event.
  """
  @spec handle_workflow_run_in_progress(
          access_token :: String.t(),
          owner :: String.t(),
          repo :: String.t(),
          map()
        ) :: any
  def handle_workflow_run_in_progress(
        _access_token,
        _owner,
        _repo,
        %{
          "workflow" => %{"id" => workflow_id},
          "workflow_run" => workflow_run_data
        } = _params
      ) do
    Logger.debug("handle_workflow_run_in_progress(#{inspect(workflow_run_data)})")

    case workflow_run_data
         |> Map.put("workflow_id", workflow_id)
         |> Workflows.create_workflow_run() do
      {:ok, workflow_run} ->
        Logger.debug("Created workflow_run: #{inspect(workflow_run)}")

      {:error, reason} ->
        Logger.error(reason)
    end
  end

  @doc """
  Actually handle the workflow_run_completed event.
  """
  @spec handle_workflow_run_completed(
          access_token :: String.t(),
          owner :: String.t(),
          repo :: String.t(),
          map()
        ) :: any
  def handle_workflow_run_completed(
        _access_token,
        _owner,
        _repo,
        %{
          "workflow" => %{"id" => workflow_id},
          "workflow_run" => workflow_run_data
        } = _params
      ) do
    Logger.debug("handle_workflow_run_completed(#{inspect(workflow_run_data)})")

    case workflow_run_data
         |> Map.put("workflow_id", workflow_id)
         |> Workflows.insert_or_update_workflow_run() do
      {:ok, workflow_run} ->
        Logger.debug("Created/updated workflow_run: #{inspect(workflow_run)}")

      {:error, reason} ->
        Logger.error(reason)
    end
  end

  @doc """
  Actually handle the workflow_job_completed event.
  """
  @spec handle_workflow_job_completed(
          access_token :: String.t(),
          owner :: String.t(),
          repo :: String.t(),
          map()
        ) :: any
  def handle_workflow_job_completed(
        access_token,
        owner,
        repo,
        %{"workflow_job" => %{"run_id" => workflow_run_id} = workflow_job_data} = _params
      ) do
    Logger.debug("handle_workflow_job_completed(#{inspect(workflow_job_data)})")

    with {:ok, _workflow_run} <-
           ensure_workflow_run_exists(access_token, owner, repo, workflow_run_id),
         {:ok, workflow_job} <-
           Gitsudo.Workflows.create_workflow_job(workflow_run_id, workflow_job_data) do
      Logger.debug("Created workflow_job: #{inspect(workflow_job)}")
      store_workflow_job_steps(workflow_job_data)
    else
      {:error, reason} ->
        Logger.error(reason)
    end
  end

  def ensure_workflow_run_exists(access_token, owner, repo, workflow_run_id) do
    if workflow_run = Workflows.get_workflow_run(workflow_run_id) do
      {:ok, workflow_run}
    else
      with {:ok, workflow_run_data} <-
             Github.Client.get_workflow_run(access_token, owner, repo, workflow_run_id) do
        Workflows.insert_or_update_workflow_run(workflow_run_data)
      end
    end
  end

  defp store_workflow_job_steps(
         %{"id" => workflow_job_id, "steps" => workflow_job_steps_data} = _workflow_job_data
       ) do
    for workflow_job_step_data <- workflow_job_steps_data do
      Logger.debug("workflow_job_step: #{inspect(workflow_job_step_data)}")

      case Gitsudo.Workflows.create_workflow_job_step(
             workflow_job_id,
             workflow_job_step_data
           ) do
        {:ok, workflow_job_step} ->
          Logger.debug("Created workflow_job_step: #{inspect(workflow_job_step)}")

        {:error, reason} ->
          Logger.error(reason)
      end
    end
  end
end

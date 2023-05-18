defmodule GitsudoWeb.WebhookController do
  @moduledoc """
  The WebhookController serves the "/webhook" endpoint.
  """
  use GitsudoWeb, :controller

  require Logger

  @spec webhook(Plug.Conn.t(), any) :: Plug.Conn.t()
  def webhook(conn, params) do
    if req_headers = conn.req_headers do
      for {key, value} <- req_headers,
          do: if(String.starts_with?(key, "x-github"), do: Logger.debug("#{key}: #{value}"))
    end

    case get_req_header(conn, "x-github-delivery") do
      [] -> Logger.warn("No x-github-delivery header found")
      [guid | _] -> File.write("tmp/#{guid}.json", Jason.encode!(params))
    end

    handle_payload(params)

    send_resp(conn, :no_content, "")
  end

  # app installation created
  def handle_payload(
        %{"action" => "created", "installation" => %{"account" => _account} = installation} =
          params
      ) do
    Logger.debug(Jason.encode!(installation))
    Gitsudo.Events.app_installation_created(params)
  end

  def handle_payload(%{"action" => "in_progress", "workflow_run" => workflow_run} = params) do
    Logger.debug(Jason.encode!(workflow_run))
    Gitsudo.Events.workflow_run_in_progress(params)
  end

  def handle_payload(%{"action" => "completed", "workflow_run" => workflow_run} = params) do
    Logger.debug(Jason.encode!(workflow_run))
    Gitsudo.Events.workflow_run_completed(params)
  end

  def handle_payload(%{"action" => "completed", "workflow_job" => workflow_job} = params) do
    Logger.debug(Jason.encode!(workflow_job))
    Gitsudo.Events.workflow_job_completed(params)
  end

  def handle_payload(params) do
    Logger.debug(
      params
      |> Map.delete("installation")
      |> Map.delete("organization")
      |> Map.delete("repository")
      |> Map.delete("sender")
      |> Jason.encode!()
    )
  end
end

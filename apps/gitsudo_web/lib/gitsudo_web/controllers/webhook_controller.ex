defmodule GitsudoWeb.WebhookController do
  @moduledoc """
  The WebhookController serves the "/webhook" endpoint.
  """
  use GitsudoWeb, :controller

  require Logger

  @spec webhook(Plug.Conn.t(), any) :: Plug.Conn.t()
  def webhook(conn, params) do
    Logger.debug(
      params
      |> Map.delete("installation")
      |> Map.delete("organization")
      |> Jason.encode!()
    )

    handle_payload(params)

    send_resp(conn, :no_content, "")
  end

  def handle_payload(%{"action" => "created"} = params) do
    Logger.debug(Jason.encode!(params))
    Gitsudo.Events.app_installation_created(params)
  end

  def handle_payload(%{"action" => "completed", "workflow_run" => workflow_run} = params) do
    Logger.debug(Jason.encode!(workflow_run))
    Gitsudo.Events.workflow_run_completed(params)
  end

  def handle_payload(%{"action" => "completed", "workflow_job" => workflow_job} = _params) do
    Logger.debug(Jason.encode!(workflow_job))
  end
end

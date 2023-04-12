defmodule GitsudoWeb.WebhookController do
  @moduledoc """
  The WebhookController serves the "/webhook" endpoint.
  """
  use GitsudoWeb, :controller

  require Logger

  @spec webhook(Plug.Conn.t(), any) :: Plug.Conn.t()
  def webhook(conn, %{"action" => "created"} = params) do
    Logger.debug(Jason.encode!(params))
    Gitsudo.Events.app_installation_created(params)
    send_resp(conn, :no_content, "")
  end

  def webhook(conn, %{"action" => "completed", "workflow_job" => workflow_job} = params) do
    Logger.debug(Jason.encode!(workflow_job))
    Gitsudo.Events.workflow_job_completed(params)
    send_resp(conn, :no_content, "")
  end

  def webhook(conn, params) do
    params
    |> Map.delete("installation")
    |> Map.delete("organization")
    |> Jason.encode!()
    |> Logger.debug()

    send_resp(conn, :no_content, "")
  end
end

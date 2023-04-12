defmodule GitsudoWeb.WebhookController do
  @moduledoc """
  The WebhookController serves the "/webhook" endpoint.
  """
  use GitsudoWeb, :controller

  require Logger

  @spec webhook(Plug.Conn.t(), any) :: Plug.Conn.t()
  def webhook(conn, %{"action" => "created"} = params) do
    Logger.debug(Jason.encode!(params))
    created = Gitsudo.Events.app_installation_created(params)
    Logger.debug("created: #{inspect(created)}")
    send_resp(conn, :no_content, "")
  end

  def webhook(conn, params) do
    params |> Map.delete("installation") |> Jason.encode!() |> Logger.debug()
    send_resp(conn, :no_content, "")
  end
end

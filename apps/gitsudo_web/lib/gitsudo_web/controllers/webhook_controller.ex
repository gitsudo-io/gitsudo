defmodule GitsudoWeb.WebhookController do
  @moduledoc """
  The WebhookController serves the "/webhook" endpoint.
  """
  use GitsudoWeb, :controller

  alias Gitsudo.GitHub

  require Logger

  @spec webhook(Plug.Conn.t(), any) :: Plug.Conn.t()
  def webhook(conn, params) do
    Logger.debug(Jason.encode!(params))
    GitHub.create_app_installation(params)
    send_resp(conn, :no_content, "")
  end
end

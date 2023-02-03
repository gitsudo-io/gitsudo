defmodule GitsudoWeb.OauthController do
  use GitsudoWeb, :controller

  require Logger

  @spec callback(Plug.Conn.t(), map()) :: Plug.Conn.t()
  def callback(conn, %{"code" => code} = _params) do
    Logger.debug("code: #{code}")
    config = Application.get_env(:gitsudo_web, GitsudoWeb.Endpoint)
    github_client_id = config[:github_client_id]
    Logger.debug("github_client_id: #{github_client_id}")
    github_client_secret = config[:github_client_secret]
    Logger.debug("github_client_secret: #{github_client_secret}")

    client_id = Application.fetch_env!(:gitsudo_web, GitsudoWeb.Endpoint)[:github_client_id]

    client_secret =
      Application.fetch_env!(:gitsudo_web, GitsudoWeb.Endpoint)[:github_client_secret]

    {:ok, access_token} =
      GitHub.Client.exchange_code_for_access_token(client_id, client_secret, code)

    Logger.debug("access_token: #{access_token}")

    render(conn, :home, layout: false)
  end
end

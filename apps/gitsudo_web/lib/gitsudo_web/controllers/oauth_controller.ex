defmodule GitsudoWeb.OauthController do
  use GitsudoWeb, :controller

  import Phoenix.Controller

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

    case Gitsudo.Accounts.handle_user_login(client_id, client_secret, code) do
      {:ok, %{user_id: user_id, exp: expires_at}} ->
        conn
        |> put_session(:user_id, user_id)
        |> put_session(:exp, expires_at)
        |> redirect(to: ~p"/")

      {:error, reason} ->
        Logger.error(inspect(reason))

        message = if is_binary(reason), do: reason, else: "Something went wrong"

        conn
        |> put_flash(:error, message)
        |> redirect(to: ~p"/login")
        |> halt()

      _ ->
        conn
        |> put_flash(:error, "Something went wrong")
        |> redirect(to: ~p"/login")
        |> halt()
    end
  end
end

defmodule GitsudoWeb.UserAuth do
  use GitsudoWeb, :verified_routes

  import Plug.Conn
  import Phoenix.Controller

  require Logger

  @doc """
  Authenticates the user by looking into the session.
  """
  def fetch_current_user(conn, _opts) do
    access_token = get_session(conn, :access_token)
    Logger.debug("access_token: #{access_token}")

    if access_token do
      with {:ok, user} <- GitHub.Client.get_user(access_token) do
        Logger.debug("user: #{inspect(user)}")
        conn |> assign(:access_token, access_token) |> assign(:current_user, user)
      else
        err ->
          Logger.error(err)
          assign(conn, :current_user, nil)
      end
    else
      assign(conn, :current_user, nil)
    end
  end

  @doc """
  Used for routes that require the user to not be authenticated.
  """
  def redirect_if_user_is_authenticated(conn, _opts) do
    if conn.assigns[:access_token] do
      conn
      |> redirect(to: signed_in_path(conn))
      |> halt()
    else
      conn
    end
  end

  @doc """
  Used for routes that require the user to be authenticated.

  If you want to enforce the user email is confirmed before
  they use the application at all, here would be a good place.
  """
  def require_authenticated_user(conn, _opts) do
    if conn.assigns[:access_token] do
      conn
    else
      conn
      |> put_flash(:error, "You must log in to access this page.")
      |> maybe_store_return_to()
      |> redirect(to: ~p"/login")
      |> halt()
    end
  end

  defp put_token_in_session(conn, token) do
    conn
    |> put_session(:user_token, token)
    |> put_session(:live_socket_id, "users_sessions:#{Base.url_encode64(token)}")
  end

  defp maybe_store_return_to(%{method: "GET"} = conn) do
    put_session(conn, :user_return_to, current_path(conn))
  end

  defp maybe_store_return_to(conn), do: conn

  defp signed_in_path(_conn), do: ~p"/"
end

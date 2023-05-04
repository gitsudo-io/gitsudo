defmodule GitsudoWeb.UserAuth do
  @moduledoc """
  The user authentication module
  """
  use GitsudoWeb, :verified_routes

  alias Gitsudo.Accounts

  import Plug.Conn
  import Phoenix.Controller

  require Logger

  @spec fetch_current_user(Plug.Conn.t(), any) :: Plug.Conn.t()
  @doc """
  Authenticates the user by looking into the session.
  """
  def fetch_current_user(conn, _opts) do
    with user_id when user_id != nil <- get_session(conn, :user_id),
         user when user != nil <- Accounts.get_account(user_id) do
      Logger.debug("user: #{inspect(user)}")
      conn |> assign(:current_user, user)
    else
      {:error, err} ->
        Logger.error(err)
        assign(conn, :current_user, nil)

      _ ->
        assign(conn, :current_user, nil)
    end
  end

  @spec redirect_if_user_is_authenticated(
          atom | %{:assigns => nil | maybe_improper_list | map, optional(any) => any},
          any
        ) :: atom | %{:assigns => nil | maybe_improper_list | map, optional(any) => any}
  @doc """
  Used for routes that require the user to not be authenticated.
  """
  def redirect_if_user_is_authenticated(conn, _opts) do
    if conn.assigns[:current_user] do
      conn
      |> redirect(to: signed_in_path(conn))
      |> halt()
    else
      conn
    end
  end

  @spec require_authenticated_user(
          atom | %{:assigns => nil | maybe_improper_list | map, optional(any) => any},
          any
        ) :: atom | %{:assigns => nil | maybe_improper_list | map, optional(any) => any}
  @doc """
  Used for routes that require the user to be authenticated.

  If you want to enforce the user email is confirmed before
  they use the application at all, here would be a good place.
  """
  def require_authenticated_user(conn, _opts) do
    if conn.assigns[:current_user] do
      conn
    else
      conn
      |> put_flash(:error, "You must log in to access this page.")
      |> maybe_store_return_to()
      |> redirect(to: ~p"/login")
      |> halt()
    end
  end

  defp maybe_store_return_to(%{method: "GET"} = conn) do
    Logger.debug("maybe_store_return_to: #{current_path(conn)}")
    put_session(conn, :user_return_to, current_path(conn))
  end

  defp maybe_store_return_to(conn), do: conn

  defp signed_in_path(_conn), do: ~p"/"
end

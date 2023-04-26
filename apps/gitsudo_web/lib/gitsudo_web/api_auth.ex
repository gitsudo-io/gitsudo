defmodule GitsudoWeb.ApiAuth do
  @moduledoc """
  The API authentication module
  """
  use GitsudoWeb, :verified_routes

  import Plug.Conn

  require Logger

  @spec init(Plug.opts()) :: Plug.opts()
  def init(options), do: options

  @spec call(conn :: Plug.Conn.t(), Plug.opts()) :: Plug.Conn.t()
  def call(conn, _opts) do
    if req_headers = conn.req_headers do
      for {key, value} <- req_headers,
          # do: if(String.starts_with?(key, "x-github"),
          do: Logger.debug("#{key}: #{value}")
    end

    if conn.assigns[:access_token] do
      conn
    else
      conn
      |> send_resp(:unauthorized, "Unauthorized")
      |> halt()
    end
  end
end

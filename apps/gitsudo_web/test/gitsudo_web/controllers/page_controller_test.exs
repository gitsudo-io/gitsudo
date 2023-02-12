defmodule GitsudoWeb.PageControllerTest do
  use GitsudoWeb.ConnCase

  test "GET /", %{conn: conn} do
    conn =
      build_conn()
      |> Plug.Test.init_test_session(access_token: SecureRandom.hex())
      |> get(~p"/")

    assert html_response(conn, 200) =~ "Repository"
  end
end

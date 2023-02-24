defmodule GitsudoWeb.PageControllerTest do
  use GitsudoWeb.ConnCase

  test "GET /", %{conn: conn} do
    # We use a GitHub personal access token for testing
    test_access_token = System.fetch_env!("TEST_PERSONAL_ACCESS_TOKEN")

    conn =
      build_conn()
      |> Plug.Test.init_test_session(access_token: test_access_token)
      |> get(~p"/")

    assert html_response(conn, 200) =~ "Repository"
  end
end

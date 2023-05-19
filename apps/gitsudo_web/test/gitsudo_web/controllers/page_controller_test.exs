defmodule GitsudoWeb.PageControllerTest do
  use GitsudoWeb.ConnCase
  use Gitsudo.VcrCase

  import GitsudoWeb.UserSessionFixtures

  setup %{conn: conn} do
    user_session = user_session_fixture()
    {:ok, conn: Plug.Test.init_test_session(conn, user_id: user_session.id)}
  end

  test "GET /", %{conn: conn} do
    use_cassette "get_home_works" do
      conn = get(conn, ~p"/")

      assert redirected_to(conn, 302) =~ "/gitsudo-io"
    end
  end
end

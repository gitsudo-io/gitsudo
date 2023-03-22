defmodule GitsudoWeb.PageControllerTest do
  use ExVCR.Mock, adapter: ExVCR.Adapter.Finch
  use GitsudoWeb.ConnCase

  setup do
    ExVCR.Config.cassette_library_dir("fixture/vcr_cassettes")
    :ok
  end

  @dummy_personal_access_token "06d5607433ef55fbfd842fd06ee740eddec4caaf"

  test "GET /", %{conn: conn} do
    # We use a GitHub personal access token for testing
    access_token = System.get_env("TEST_PERSONAL_ACCESS_TOKEN", @dummy_personal_access_token)
    ExVCR.Config.filter_sensitive_data(access_token, @dummy_personal_access_token)

    use_cassette "get_home_works" do
      conn =
        build_conn()
        |> Plug.Test.init_test_session(access_token: access_token)
        |> get(~p"/")

      assert html_response(conn, 200) =~ "Repository"
    end
  end
end

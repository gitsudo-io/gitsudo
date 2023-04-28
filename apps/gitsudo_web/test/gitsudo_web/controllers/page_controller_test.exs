defmodule GitsudoWeb.PageControllerTest do
  use GitsudoWeb.ConnCase
  use ExVCR.Mock, adapter: ExVCR.Adapter.Finch

  setup do
    ExVCR.Config.cassette_library_dir("test/fixtures/vcr_cassettes")
    :ok
  end

  @dummy_personal_access_token "06d5607433ef55fbfd842fd06ee740eddec4caaf"

  setup do
    # credo:disable-for-next-line
    {:ok, _account} =
      Gitsudo.Accounts.find_or_create_account(121_780_924, %{
        "login" => "gitsudo-io",
        "type" => "Organization"
      })

    :ok
  end

  test "GET /", %{conn: conn} do
    # We use a GitHub personal access token for testing
    access_token = System.get_env("TEST_PERSONAL_ACCESS_TOKEN", @dummy_personal_access_token)
    ExVCR.Config.filter_sensitive_data(access_token, @dummy_personal_access_token)

    use_cassette "get_home_works" do
      conn =
        conn
        |> Plug.Test.init_test_session(access_token: access_token)
        |> get(~p"/")

      assert html_response(conn, 200) =~ "Repository"
    end
  end
end

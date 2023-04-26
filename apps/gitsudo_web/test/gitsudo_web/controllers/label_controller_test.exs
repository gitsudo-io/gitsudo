defmodule GitsudoWeb.LabelControllerTest do
  use GitsudoWeb.ConnCase
  use ExVCR.Mock, adapter: ExVCR.Adapter.Finch

  import Gitsudo.LabelsFixtures

  alias Gitsudo.Labels.Label

  require Logger

  setup do
    ExVCR.Config.cassette_library_dir("test/fixtures/vcr_cassettes")
    :ok
  end

  @dummy_personal_access_token "06d5607433ef55fbfd842fd06ee740eddec4caaf"

  setup %{conn: conn} do
    {:ok, _account} =
      Gitsudo.Accounts.find_or_create_account(121_780_924, %{
        "login" => "gitsudo-io",
        "type" => "Organization"
      })

    access_token = System.get_env("TEST_PERSONAL_ACCESS_TOKEN", @dummy_personal_access_token)
    ExVCR.Config.filter_sensitive_data(access_token, @dummy_personal_access_token)

    {:ok, conn: Plug.Test.init_test_session(conn, access_token: access_token)}
  end

  describe "index" do
    setup [:create_label]

    test "lists all labels", %{conn: conn, label: label} do
      use_cassette "get_home_works" do
        conn = get(conn, ~p"/gitsudo-io/labels")

        assert html_response(conn, 200) =~ label.name
      end
    end
  end

  describe "show" do
    setup [:create_label]

    test "shows a label", %{conn: conn, label: label} do
      use_cassette "get_home_works" do
        conn = get(conn, ~p"/gitsudo-io/labels/#{label.name}")

        assert html_response(conn, 200) =~ label.name
      end
    end

    test "404 on non-existent label", %{conn: conn} do
      use_cassette "get_home_works" do
        conn = get(conn, ~p"/gitsudo-io/labels/not-a-label")

        assert response(conn, 404)
      end
    end
  end

  defp create_label(_) do
    label = label_fixture()
    %{label: label}
  end
end

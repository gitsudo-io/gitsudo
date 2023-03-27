defmodule GitsudoWeb.LabelControllerTest do
  use GitsudoWeb.ConnCase

  import Gitsudo.LabelsFixtures

  alias Gitsudo.Labels.Label

  require Logger

  @dummy_personal_access_token "06d5607433ef55fbfd842fd06ee740eddec4caaf"

  setup %{conn: conn} do
    {:ok, _account} =
      Gitsudo.Accounts.find_or_create_account(42, %{
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
      conn = get(conn, ~p"/gitsudo-io/labels")

      assert html_response(conn, 200) =~ label.name
    end
  end

  describe "show" do
    setup [:create_label]

    test "shows a label", %{conn: conn, label: label} do
      conn = get(conn, ~p"/gitsudo-io/labels/#{label.name}")

      assert html_response(conn, 200) =~ label.name
    end

    test "404 on non-existent label", %{conn: conn} do
      conn = get(conn, ~p"/gitsudo-io/labels/not-a-label")

      assert response(conn, 404)
    end
  end

  defp create_label(_) do
    label = label_fixture()
    %{label: label}
  end
end

defmodule GitsudoWeb.LabelControllerTest do
  use GitsudoWeb.ConnCase
  use Gitsudo.VcrCase

  import Gitsudo.LabelsFixtures
  import GitsudoWeb.UserSessionFixtures

  alias Gitsudo.Labels.Label

  require Logger

  setup %{conn: conn} do
    user_session = user_session_fixture()
    conn = Plug.Conn.assign(conn, :user_role, "admin")
    {:ok, conn: Plug.Test.init_test_session(conn, user_id: user_session.id)}
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

  describe "update" do
    setup [:create_label]

    test "can add a team policy", %{conn: conn, label: %{owner: owner} = label} do
      conn =
        put(conn, ~p"/gitsudo-io/labels/#{label.name}", %{
          label: %{
            name: label.name,
            description: label.description,
            color: label.color
          },
          team_permissions_ids: [""],
          team_permissions_teams: ["a-team"],
          team_permissions_permissions: ["pull"]
        })

      assert html_response(conn, 302) =~ "#{owner.login}/labels/#{label.name}"

      updated = Gitsudo.Labels.get_label!(owner.id, label.id, preload: [:team_policies])
      assert length(updated.team_policies) == 1
      first_policy = Enum.at(updated.team_policies, 0)
      assert first_policy.team_slug == "a-team"
      assert first_policy.permission == :pull
    end
  end

  defp create_label(_) do
    label = label_fixture()
    %{label: label}
  end
end

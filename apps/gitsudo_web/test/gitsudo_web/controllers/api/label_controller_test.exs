defmodule GitsudoWeb.LabelControllerTest do
  use GitsudoWeb.ConnCase

  import Gitsudo.LabelsFixtures

  alias Gitsudo.Labels.Label

  @create_attrs %{
    color: "some color",
    name: "some name",
    owner_id: 42
  }
  @update_attrs %{
    color: "some updated color",
    name: "some updated name",
    owner_id: 43
  }
  @invalid_attrs %{color: nil, name: nil, owner_id: nil}

  setup %{conn: conn} do
    {:ok, _account} =
      Gitsudo.Accounts.find_or_create_account(42, %{
        "login" => "gitsudo-io",
        "type" => "Organization"
      })

    {:ok, conn: put_req_header(conn, "accept", "application/json")}
  end

  describe "index" do
    test "lists all labels", %{conn: conn} do
      conn = get(conn, ~p"/api/org/gitsudo-io/labels")
      assert json_response(conn, 200)["data"] == []
    end
  end

  describe "create label" do
    test "renders label when data is valid", %{conn: conn} do
      conn = post(conn, ~p"/api/labels", label: @create_attrs)
      assert %{"id" => id} = json_response(conn, 201)["data"]

      conn = get(conn, ~p"/api/labels/#{id}")

      assert %{
               "id" => ^id,
               "color" => "some color",
               "name" => "some name",
               "owner_id" => 42
             } = json_response(conn, 200)["data"]
    end

    test "renders errors when data is invalid", %{conn: conn} do
      conn = post(conn, ~p"/api/labels", label: @invalid_attrs)
      assert json_response(conn, 422)["errors"] != %{}
    end
  end

  describe "update label" do
    setup [:create_label]

    test "renders label when data is valid", %{conn: conn, label: %Label{id: id} = label} do
      conn = put(conn, ~p"/api/labels/#{label}", label: @update_attrs)
      assert %{"id" => ^id} = json_response(conn, 200)["data"]

      conn = get(conn, ~p"/api/labels/#{id}")

      assert %{
               "id" => ^id,
               "color" => "some updated color",
               "name" => "some updated name",
               "owner_id" => 43
             } = json_response(conn, 200)["data"]
    end

    test "renders errors when data is invalid", %{conn: conn, label: label} do
      conn = put(conn, ~p"/api/labels/#{label}", label: @invalid_attrs)
      assert json_response(conn, 422)["errors"] != %{}
    end
  end

  describe "delete label" do
    setup [:create_label]

    test "deletes chosen label", %{conn: conn, label: label} do
      conn = delete(conn, ~p"/api/labels/#{label}")
      assert response(conn, 204)

      assert_error_sent 404, fn ->
        get(conn, ~p"/api/labels/#{label}")
      end
    end
  end

  defp create_label(_) do
    label = label_fixture()
    %{label: label}
  end
end

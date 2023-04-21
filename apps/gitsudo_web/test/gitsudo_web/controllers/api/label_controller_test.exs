defmodule GitsudoWeb.API.LabelControllerTest do
  use GitsudoWeb.ConnCase

  import Gitsudo.LabelsFixtures

  alias Gitsudo.Labels.Label

  require Logger

  @dummy_personal_access_token "06d5607433ef55fbfd842fd06ee740eddec4caaf"

  @update_attrs %{
    color: "some updated color",
    name: "some updated name"
  }
  @invalid_attrs %{color: nil, name: nil}

  setup %{conn: conn} do
    {:ok, _account} =
      Gitsudo.Accounts.find_or_create_account(42, %{
        "login" => "gitsudo-io",
        "type" => "Organization"
      })

    access_token = System.get_env("TEST_PERSONAL_ACCESS_TOKEN", @dummy_personal_access_token)
    ExVCR.Config.filter_sensitive_data(access_token, @dummy_personal_access_token)

    {:ok,
     conn:
       conn
       |> put_req_header("accept", "application/json")
       |> Plug.Test.init_test_session(access_token: access_token)}
  end

  describe "index" do
    setup [:create_label]

    test "lists all labels", %{conn: conn, label: label} do
      conn = get(conn, ~p"/api/org/gitsudo-io/labels")
      assert json_response(conn, 200)
      assert data = json_response(conn, 200)["data"]
      assert length(data) > 0

      assert data == [
               %{
                 "id" => label.id,
                 "color" => "label-red",
                 "name" => "backend",
                 "owner_id" => 42
               }
             ]
    end
  end

  describe "create label" do
    test "renders label when data is valid", %{conn: conn} do
      conn =
        post(conn, ~p"/api/org/gitsudo-io/labels",
          label: %{"color" => "label-green", "name" => "green"}
        )

      assert %{"id" => id} = json_response(conn, 201)["data"]

      conn = get(conn, ~p"/api/org/gitsudo-io/labels/#{id}")

      assert %{
               "id" => ^id,
               "color" => "label-green",
               "name" => "green",
               "owner_id" => 42
             } = json_response(conn, 200)["data"]
    end

    test "renders errors when data is invalid", %{conn: conn} do
      conn = post(conn, ~p"/api/org/gitsudo-io/labels", label: %{"name" => ""})
      assert json_response(conn, 422)["errors"] != %{}
    end
  end

  describe "update label" do
    setup [:create_label]

    test "rename label", %{conn: conn, label: %Label{id: id} = label} do
      conn = put(conn, ~p"/api/org/gitsudo-io/labels/#{label}", label: %{name: "new-name"})
      assert %{"id" => ^id} = json_response(conn, 200)["data"]

      conn = get(conn, ~p"/api/org/gitsudo-io/labels/#{label}")

      assert %{
               "id" => ^id,
               "color" => "label-red",
               "name" => "new-name",
               "owner_id" => 42
             } = json_response(conn, 200)["data"]
    end

    test "renders label when data is valid", %{conn: conn, label: %Label{id: id} = label} do
      conn = put(conn, ~p"/api/org/gitsudo-io/labels/#{label}", label: @update_attrs)
      assert %{"id" => ^id} = json_response(conn, 200)["data"]

      conn = get(conn, ~p"/api/org/gitsudo-io/labels/#{label}")

      assert %{
               "id" => ^id,
               "color" => "some updated color",
               "name" => "some updated name",
               "owner_id" => 42
             } = json_response(conn, 200)["data"]
    end

    test "renders errors when data is invalid", %{conn: conn, label: label} do
      Logger.debug("label => #{inspect(label)}")
      conn = put(conn, ~p"/api/org/gitsudo-io/labels/#{label}", label: @invalid_attrs)
      assert json_response(conn, 422)["errors"] != %{}
    end
  end

  describe "delete label" do
    setup [:create_label]

    test "deletes chosen label", %{conn: conn, label: label} do
      conn = delete(conn, ~p"/api/org/gitsudo-io/labels/#{label}")

      assert response(conn, 204)

      assert_error_sent 404, fn ->
        get(conn, ~p"/api/org/gitsudo-io/labels/#{label}")
      end
    end
  end

  defp create_label(_) do
    label = label_fixture()
    %{label: label}
  end
end

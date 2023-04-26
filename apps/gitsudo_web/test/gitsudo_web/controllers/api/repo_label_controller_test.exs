defmodule GitsudoWeb.API.RepoLabelControllerTest do
  use ExVCR.Mock, adapter: ExVCR.Adapter.Finch
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
      Gitsudo.Accounts.find_or_create_account(121_780_924, %{
        "login" => "gitsudo-io",
        "type" => "Organization"
      })

    {:ok, repository} =
      Gitsudo.Repositories.find_or_create_repository(%{
        "id" => 596_202_192,
        "name" => "gitsudo",
        "html_url" => "https://github.com/gitsudo-io/gitsudo",
        "owner" => %{
          "id" => 121_780_924,
          "login" => "gitsudo-io",
          "type" => "Organization"
        }
      })

    label = label_fixture()
    Logger.debug("label: #{inspect(label)}")

    {:ok, r} = Gitsudo.Repositories.add_label_to_repository(repository, label)
    Logger.debug("r: #{inspect(r)}")

    conn =
      conn
      |> put_req_header("accept", "application/json")
      |> Plug.Test.init_test_session(access_token: @dummy_personal_access_token)

    {:ok, conn: conn, label: label}
  end

  describe "index" do
    test "lists repo labels", %{conn: conn, label: label} do
      use_cassette("lists_repo_labels_works") do
        conn = get(conn, ~p"/api/org/gitsudo-io/gitsudo/labels")
        assert json_response(conn, 200)
        assert data = json_response(conn, 200)["data"]
        assert length(data) > 0

        assert data == [
                 %{
                   "id" => label.id,
                   "color" => "label-red",
                   "name" => "backend",
                   "owner_id" => 121_780_924,
                   "collaborator_policies" => []
                 }
               ]
      end
    end
  end
end

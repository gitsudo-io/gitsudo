defmodule GitHub.ClientTest do
  use ExUnit.Case, async: true
  use ExVCR.Mock, adapter: ExVCR.Adapter.Finch

  alias GitHub.Client

  require Logger

  @dummy_personal_access_token "06d5607433ef55fbfd842fd06ee740eddec4caaf"

  setup do
    ExVCR.Config.cassette_library_dir("fixture/vcr_cassettes")

    if test_access_token = System.get_env("TEST_PERSONAL_ACCESS_TOKEN") do
      ExVCR.Config.filter_sensitive_data(test_access_token, @dummy_personal_access_token)
    end

    :ok
  end

  describe "client" do
    test "list_app_installations/2 works" do
      use_cassette "list_app_installations_works" do
        app_id = "287942"
        key_pem = File.read!(System.fetch_env!("GITHUB_APP_PRIVATE_KEY_FILE"))

        {:ok, [first | _] = installations} = Client.list_app_installations(app_id, key_pem)

        assert 1 == Enum.count(installations)
        # credo:disable-for-next-line
        assert 34_222_363 == first["id"]
      end
    end

    test "get_app_installation_access_token/3 works" do
      use_cassette "get_app_installation_access_token_works" do
        app_id = "287942"
        key_pem = File.read!(System.fetch_env!("GITHUB_APP_PRIVATE_KEY_FILE"))

        access_tokens_url = "https://api.github.com/app/installations/34222363/access_tokens"

        {:ok, resp} = Client.get_app_installation_access_token(app_id, key_pem, access_tokens_url)

        assert "jDBs1BJ8PX27u05MIDW73pViiQSxwZrDz5pqeVma" == resp["token"]
      end
    end

    test "exchange_code_for_access_token/3 works" do
      use_cassette "exchange_code_for_access_token_works" do
        # A dummy Github app client id
        client_id = "18f02e1f6980f49baf4c"

        # A dummy GitHub app client secret
        client_secret = "2c28c12f232c36f9feb6f91644f416e08a286fcb"

        code = "b1ecef51a773c4ee17ab"

        {:ok, %{"access_token" => access_token}} =
          Client.exchange_code_for_access_token(client_id, client_secret, code)

        assert @dummy_personal_access_token == access_token
      end
    end

    test "put_team_repository_permission/4 works" do
      use_cassette "client_put_team_repository_permission_works" do
        org = "gitsudo-io"
        team_slug = "test-team-a"
        owner = "gitsudo-io"
        repo = "test-repo-alpha"
        permission = "push"

        {:ok, nil} =
          Client.put_team_repository_permission(
            @dummy_personal_access_token,
            org,
            team_slug,
            owner,
            repo,
            permission
          )
      end
    end

    test "get_repo/3 works" do
      use_cassette "client_get_repo_works" do
        {:ok, repo} = Client.get_repo(@dummy_personal_access_token, "gitsudo-io", "gitsudo")
        assert "gitsudo" == repo["name"]
        # credo:disable-for-next-line
        assert 596_202_192 == repo["id"]
        # credo:disable-for-next-line
        assert 121_780_924 == repo["owner"]["id"]
      end
    end

    test "get_user/1 works" do
      use_cassette "client_get_user_works" do
        {:ok, user} = Client.get_user(@dummy_personal_access_token)
        assert "aisrael" == user["login"]
        # credo:disable-for-next-line
        assert 89215 == user["id"]
      end
    end

    test "with_all_workflow_runs/5 works do" do
      use_cassette "with_all_workflow_runs_works", match_requests_on: [:query] do
        fun = fn page, results ->
          {:cont, results ++ page["workflow_runs"]}
        end

        workflow_runs =
          Client.with_all_workflow_runs(
            @dummy_personal_access_token,
            "gitsudo-io",
            "gitsudo",
            [],
            fun
          )

        assert 44 == Enum.count(workflow_runs)
        # credo:disable-for-next-line
        assert 4_490_840_000 == Enum.at(workflow_runs, 43)["id"]
      end
    end
  end
end

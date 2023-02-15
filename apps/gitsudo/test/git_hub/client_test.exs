defmodule GitHub.ClientTest do
  use ExUnit.Case, async: true
  use ExVCR.Mock, adapter: ExVCR.Adapter.Hackney

  alias GitHub.Client

  setup do
    ExVCR.Config.cassette_library_dir("fixture/vcr_cassettes")
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
        assert 34222363 == first["id"]
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

        {:ok, access_token} =
          Client.exchange_code_for_access_token(client_id, client_secret, code)

        assert "06d5607433ef55fbfd842fd06ee740eddec4caaf" == access_token
      end
    end

    test "get_user/1 works" do
      use_cassette "client_get_user_works" do
        {:ok, user} = Client.get_user("06d5607433ef55fbfd842fd06ee740eddec4caaf")
        assert "aisrael" == user["login"]
        # credo:disable-for-next-line
        assert 89215 == user["id"]
      end
    end
  end
end

defmodule GitHub.ClientTest do
  use ExUnit.Case, async: true
  use ExVCR.Mock, adapter: ExVCR.Adapter.Hackney

  alias GitHub.Client

  setup do
    ExVCR.Config.cassette_library_dir("fixture/vcr_cassettes")
    :ok
  end

  describe "client" do
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
        assert 89215 == user["id"]
      end
    end
  end
end

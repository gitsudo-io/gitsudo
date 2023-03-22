defmodule GitHub.TokenCacheTest do
  use ExUnit.Case, async: true
  use ExVCR.Mock, adapter: ExVCR.Adapter.Finch

  require Logger

  setup do
    app_id = Application.fetch_env!(:github, GitHub)[:github_app_id]

    key_pem = File.read!(System.fetch_env!("GITHUB_APP_PRIVATE_KEY_FILE"))
    GitHub.TokenCache.start_link(app_id: app_id, key_pem: key_pem)

    ExVCR.Config.cassette_library_dir("fixture/vcr_cassettes")
    :ok
  end

  describe "token_cache" do
    test "get_or_refresh_token/1 works" do
      # credo:disable-for-next-line
      installation_id = 34_261_427

      use_cassette "token_cache_get_or_refresh_token_works" do
        {:ok, token} = GitHub.TokenCache.get_or_refresh_token(installation_id)
        Logger.debug(token)
        assert token
      end

      # check that the token is still there
      {:ok, existing_token} = GitHub.TokenCache.get_token(installation_id)
      Logger.debug(existing_token)
      assert existing_token
    end
  end
end

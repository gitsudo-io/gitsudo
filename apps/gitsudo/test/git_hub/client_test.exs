defmodule GitHub.ClientTest do
  use ExUnit.Case, async: true
  use ExVCR.Mock, adapter: ExVCR.Adapter.Hackney

  alias GitHub.Client

  setup do
    ExVCR.Config.cassette_library_dir("fixture/vcr_cassettes")
    :ok
  end

  describe "client" do
    test "get_user/1 works" do
      use_cassette "client_get_user_works" do
        {:ok, user} = Client.get_user("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")
        assert "aisrael" == user["login"]
        assert 89215 == user["id"]
      end
    end
  end
end

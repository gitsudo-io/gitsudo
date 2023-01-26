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
        Client.get_user("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")
      end
    end
  end
end

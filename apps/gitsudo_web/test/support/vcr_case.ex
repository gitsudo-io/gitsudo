defmodule Gitsudo.VcrCase do
  @moduledoc """
  This module defines the test case to be used by
  tests that require ExVCR recording of GitHub API interactions.

  Such tests rely on `Phoenix.ConnTest` and also
  import other functionality to make it easier
  to build common data structures and query the data layer.

  Finally, if the test case interacts with the database,
  we enable the SQL sandbox, so changes done to the database
  are reverted at the end of every test. If you are using
  PostgreSQL, you can even run database tests asynchronously
  by setting `use GitsudoWeb.ConnCase, async: true`, although
  this option is not recommended for other databases.
  """

  use ExUnit.CaseTemplate

  # A dummy personal access token
  @dummy_personal_access_token "06d5607433ef55fbfd842fd06ee740eddec4caaf"

  using do
    quote do
      use ExVCR.Mock, adapter: ExVCR.Adapter.Finch
    end
  end

  setup do
    ExVCR.Config.cassette_library_dir("test/fixtures/vcr_cassettes")

    # We use a GitHub personal access token for testing
    test_personal_access_token =
      System.get_env("TEST_PERSONAL_ACCESS_TOKEN", @dummy_personal_access_token)

    ExVCR.Config.filter_sensitive_data(test_personal_access_token, @dummy_personal_access_token)

    {:ok, test_personal_access_token: test_personal_access_token}
  end
end

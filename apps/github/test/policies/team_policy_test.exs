defmodule GitHub.Policies.TeamPolicyTest do
  use ExUnit.Case, async: true
  use ExVCR.Mock, adapter: ExVCR.Adapter.Finch

  require Logger

  @dummy_personal_access_token "06d5607433ef55fbfd842fd06ee740eddec4caaf"

  setup do
    ExVCR.Config.cassette_library_dir("fixture/vcr_cassettes")

    if test_access_token = System.get_env("TEST_PERSONAL_ACCESS_TOKEN") do
      ExVCR.Config.filter_sensitive_data(test_access_token, @dummy_personal_access_token)
    end

    access_token = System.get_env("TEST_PERSONAL_ACCESS_TOKEN") || @dummy_personal_access_token

    {:ok, access_token: access_token}
  end

  test "TeamPolicy.apply works", %{access_token: access_token} do
    use_cassette("test_team_policy_apply_works") do
      policy = %GitHub.Policies.TeamPolicy{
        team_slug: "a-team",
        permission: "maintain"
      }

      {:ok, %{status: 204} = result} =
        GitHub.Policies.TeamPolicy.apply(access_token, policy, 621_016_081)

      {:ok,
       %{
         "permissions" => %{
           "admin" => false,
           "maintain" => true,
           "push" => true,
           "triage" => true,
           "pull" => true
         }
       } = _resp} =
        GitHub.Client.get_team_repository_permissions(
          access_token,
          "gitsudo-io",
          "a-team",
          "gitsudo-io",
          "test-repo-alpha"
        )
    end
  end
end

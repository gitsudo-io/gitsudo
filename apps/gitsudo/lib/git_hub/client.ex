defmodule GitHub.Client do
  @moduledoc """
  The high-level GitHub client
  """

  @spec get_user(binary()) :: map()
  def get_user(access_token) do
    {:ok, resp} =
      HTTPoison.get("https://api.github.com/user", [
        {"Authorization", "Bearer #{access_token}"},
        {"Accept", "application/json"}
      ])

    Jason.decode!(resp.body)
  end
end

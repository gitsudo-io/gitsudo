defmodule GitHub.Client do
  @moduledoc """
  The high-level GitHub client
  """

  @spec get_user(binary()) :: {:ok, map()} | {:error, any()}
  def get_user(access_token) do
    case HTTPoison.get("https://api.github.com/user", [
           {"Authorization", "Bearer #{access_token}"},
           {"Accept", "application/json"}
         ]) do
      {:ok, resp} -> Jason.decode(resp.body)
      {:error, err} -> {:error, err}
    end
  end
end

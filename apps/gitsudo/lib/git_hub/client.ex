defmodule GitHub.Client do
  @moduledoc """
  The high-level GitHub client
  """

  require Logger

  @doc """
  Get app installations
  """
  @spec get_app_installations(String.t(), String.t()) ::
          {:ok, map()} | {:error, any()}
  def get_app_installations(private_key, app_id) do
    signer = Joken.Signer.create("RS256", %{"pem" => private_key})
    iat = :os.system_time(:second)

    payload = %{
      "aud" => "Gitsudo",
      "iss" => app_id,
      "iat" => iat,
      "exp" => iat + 600
    }

    with {:ok, token, _} <- Gitsudo.Token.generate_and_sign(payload, signer),
         {:ok, resp} <-
           HTTPoison.get("https://api.github.com/app/installations", [
             {"Authorization", "Bearer #{token}"}
           ]) do
      Jason.decode(resp.body)
    else
      {:error, err} -> {:error, err}
    end
  end

  @doc """
  Exchange the temporary OAuth redirect code for an access token.
  """
  @spec exchange_code_for_access_token(
          client_id :: String.t(),
          client_secret :: String.t(),
          code :: String.t()
        ) ::
          {:ok, String.t()} | {:error, any}
  def exchange_code_for_access_token(client_id, client_secret, code) do
    body = Jason.encode!(%{client_id: client_id, client_secret: client_secret, code: code})
    Logger.debug(body)
    url = "https://github.com/login/oauth/access_token"

    with {:ok, resp} <-
           HTTPoison.post(url, body, [
             {"Content-Type", "application/json"},
             {"Accept", "application/json"}
           ]),
         %{"access_token" => access_token} <- Jason.decode!(resp.body) do
      {:ok, access_token}
    else
      {:error, err} -> {:error, err}
    end
  end

  @doc """
  Get the logged in user associated with an access token, if available.
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

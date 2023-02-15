defmodule GitHub.Client do
  @moduledoc """
  The low-level GitHub client
  """

  require Logger

  @doc """
  List app installations
  """
  @spec list_app_installations(app_id :: String.t(), key_pem :: String.t()) ::
          {:ok, map()} | {:error, any()}
  def list_app_installations(app_id, key_pem) do
    signer = Joken.Signer.create("RS256", %{"pem" => key_pem})
    iat = :os.system_time(:second)

    payload = %{
      "aud" => "Gitsudo",
      "iss" => app_id,
      "iat" => iat,
      "exp" => iat + 600
    }

    with {:ok, token, _} <- Gitsudo.Token.generate_and_sign(payload, signer),
         {:ok, resp} <- http_get_api(token, "app/installations") do
      Jason.decode(resp.body)
    end
  end

  @doc """
  Get app access token
  """
  @spec get_app_installation_access_token(
          app_id :: String.t(),
          key_pem :: String.t(),
          access_tokens_url :: String.t()
        ) ::
          {:ok, map()} | {:error, any()}
  def get_app_installation_access_token(app_id, key_pem, access_tokens_url) do
    signer = Joken.Signer.create("RS256", %{"pem" => key_pem})
    iat = :os.system_time(:second)

    payload = %{
      "aud" => "Gitsudo",
      "iss" => app_id,
      "iat" => iat,
      "exp" => iat + 600
    }

    with {:ok, token, _} <- Gitsudo.Token.generate_and_sign(payload, signer),
         {:ok, resp} <- http_post(token, access_tokens_url, "") do
      Jason.decode(resp.body)
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
    end
  end

  def list_org_repos(access_token, org) do
    http_get_and_decode(access_token, "orgs/#{org}/repos")
  end

  @doc """
  Get the logged in user associated with an access token, if available.

  ```
    GET /user
  ```
  """
  @spec get_user(binary()) :: {:ok, map()} | {:error, HTTPoison.Error.t()}
  def get_user(access_token) do
    http_get_and_decode(access_token, "user")
  end

  @doc """
  ```
    GET /user/repos
  ```
  """
  @spec list_user_repositories(binary) ::
          {:ok, any} | {:error, HTTPoison.Error.t() | Jason.DecodeError.t()}
  def list_user_repositories(access_token) do
    http_get_and_decode(access_token, "user/repos")
  end

  @doc """
  ```
    GET /user/orgs
  ```
  """
  @spec list_user_orgs(binary) ::
          {:ok, any} | {:error, HTTPoison.Error.t() | Jason.DecodeError.t()}
  def list_user_orgs(access_token) do
    http_get_and_decode(access_token, "user/orgs")
  end

  @spec http_get_and_decode(binary, binary) ::
          {:ok, any} | {:error, HTTPoison.Error.t() | Jason.DecodeError.t()}
  defp http_get_and_decode(access_token, path) when is_binary(access_token) and is_binary(path) do
    with {:ok, resp} <- http_get_api(access_token, path) do
      Jason.decode(resp.body)
    end
  end

  # Construct an HTTPoison.get request to the given path with the given access token
  # as the `Authorization: Bearer` token.
  @spec http_get_api(access_token :: String.t(), path :: String.t()) ::
          {:ok, HTTPoison.Response.t() | HTTPoison.AsyncResponse.t()}
          | {:error, HTTPoison.Error.t()}
  defp http_get_api(access_token, path)
       when is_binary(access_token) and
              is_binary(path) do
    url = "https://api.github.com/#{path}"
    Logger.debug("GET #{url}")

    HTTPoison.get(url, [
      {"Authorization", "Bearer #{access_token}"},
      {"Content-Type", "application/json"},
      {"Accept", "application/json"}
    ])
  end

  @spec http_post(access_token :: String.t(), url :: String.t(), body :: String.t()) ::
          {:ok, HTTPoison.Response.t() | HTTPoison.AsyncResponse.t()}
          | {:error, HTTPoison.Error.t()}
  defp http_post(access_token, url, body) when is_binary(access_token) and is_binary(url) do
    HTTPoison.post(url, body, [
      {"Authorization", "Bearer #{access_token}"},
      {"Content-Type", "application/json"},
      {"Accept", "application/json"}
    ])
  end
end

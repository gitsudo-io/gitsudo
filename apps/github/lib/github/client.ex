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

    with {:ok, token, _} <- GitHub.Token.generate_and_sign(payload, signer),
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
    get_app_installation_access_token_with_signer(app_id, signer, access_tokens_url)
  end

  @doc """
  Get app access token with a Joken.Signer
  """
  @spec get_app_installation_access_token_with_signer(
          app_id :: String.t(),
          signer :: Joken.Signer.t(),
          access_tokens_url :: String.t()
        ) ::
          {:ok, map()} | {:error, any()}
  def get_app_installation_access_token_with_signer(
        app_id,
        %Joken.Signer{} = signer,
        access_tokens_url
      ) do
    Logger.debug("app_id: #{app_id}")
    Logger.debug("key_thumprint: #{JOSE.JWK.thumbprint(signer.jwk)}")
    Logger.debug("access_tokens_url: #{access_tokens_url}")

    iat = :os.system_time(:second)

    payload = %{
      "aud" => "Gitsudo",
      "iss" => app_id,
      "iat" => iat,
      "exp" => iat + 600
    }

    with {:ok, token, _} <- GitHub.Token.generate_and_sign(payload, signer),
         {:ok, resp} <- http_post(token, access_tokens_url, "") do
      if 201 == resp.status do
        Logger.debug(resp.body)
        Jason.decode(resp.body)
      else
        Logger.debug("resp.status: #{resp.status}")
        reason = "#{resp.status} #{Plug.Conn.Status.reason_phrase(resp.status)}"
        Logger.error(reason)
        {:error, reason}
      end
    else
      {:error, reason} ->
        Logger.error(reason)
        {:error, reason}
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
          {:ok, term} | {:error, Exception.t() | Jason.DecodeError.t()}
  def exchange_code_for_access_token(client_id, client_secret, code) do
    with {:ok, body} <-
           Jason.encode(%{client_id: client_id, client_secret: client_secret, code: code}) do
      Logger.debug(body)
      url = "https://github.com/login/oauth/access_token"

      with {:ok, resp} <-
             Finch.build(
               :post,
               url,
               [
                 {"Content-Type", "application/json"},
                 {"Accept", "application/json"}
               ],
               body
             )
             |> Finch.request(GitHub.Finch) do
        Jason.decode(resp.body)
      end
    end
  end

  @doc """
  List all the repos under the given organization visible to the given access token.

  ```
    GET /org/{owner}/repos
  ```
  """
  @spec list_org_repos(access_token :: String.t(), organization_name :: String.t()) ::
          {:ok, list()} | {:error, String.t() | Exception.t() | Jason.DecodeError.t()}
  def list_org_repos(access_token, organization_name) do
    http_get_and_decode(access_token, "orgs/#{organization_name}/repos")
  end

  @doc """
  Get the logged in user associated with an access token, if available.

  ```
    GET /user
  ```
  """
  @spec get_user(binary) ::
          {:ok, map()} | {:error, String.t() | Exception.t() | Jason.DecodeError.t()}
  def get_user(access_token) do
    http_get_and_decode(access_token, "user")
  end

  @doc """
  ```
    GET /user/repos
  ```
  """
  @spec list_user_repositories(binary) ::
          {:ok, map()} | {:error, String.t() | Exception.t() | Jason.DecodeError.t()}
  def list_user_repositories(access_token) do
    http_get_and_decode(access_token, "user/repos")
  end

  @doc """
  ```
    GET /user/orgs
  ```
  """
  @spec list_user_orgs(access_token :: String.t()) ::
          {:ok, list()} | {:error, String.t() | Exception.t() | Jason.DecodeError.t()}
  def list_user_orgs(access_token) do
    http_get_and_decode(access_token, "user/orgs")
  end

  @doc """
  List workflows for a given repository

  ```
    GET /repos/{owner}/{repo}/actions/workflows
  ```
  """
  @spec list_workflows(access_token :: String.t(), owner :: String.t(), repo :: String.t()) ::
          {:ok, map()} | {:error, String.t() | Exception.t() | Jason.DecodeError.t()}
  def list_workflows(access_token, owner, repo) do
    http_get_and_decode(access_token, "repos/#{owner}/#{repo}/actions/workflows")
  end

  @doc """
  List workflow runs for a given repository

  ```
    GET /repos/{owner}/{repo}/actions/runs
  ```
  """
  @spec list_workflow_runs(access_token :: String.t(), owner :: String.t(), repo :: String.t()) ::
          {:ok, map()} | {:error, String.t() | Exception.t() | Jason.DecodeError.t()}
  def list_workflow_runs(access_token, owner, repo) do
    http_get_and_decode(access_token, "repos/#{owner}/#{repo}/actions/runs")
  end

  @spec http_get_and_decode(binary, binary) ::
          {:ok, any} | {:error, String.t() | Exception.t() | Jason.DecodeError.t()}
  defp http_get_and_decode(access_token, path) when is_binary(access_token) and is_binary(path) do
    with {:ok, resp} <- http_get_api(access_token, path) do
      if 200 == resp.status do
        Jason.decode(resp.body)
      else
        Logger.debug("resp.status: #{resp.status}")
        {:error, "#{resp.status} #{Plug.Conn.Status.reason_phrase(resp.status)}"}
      end
    end
  end

  # Construct an HTTPoison.get request to the given path with the given access token
  # as the `Authorization: Bearer` token.
  @spec http_get_api(access_token :: String.t(), path :: String.t()) ::
          {:ok, Finch.Response.t()} | {:error, Exception.t()}
  defp http_get_api(access_token, path)
       when is_binary(access_token) and
              is_binary(path) do
    url = "https://api.github.com/#{path}"
    Logger.debug("GET #{url}")

    Finch.build(:get, url, [
      {"Authorization", "Bearer #{access_token}"},
      {"Content-Type", "application/json"},
      {"Accept", "application/json"}
    ])
    |> Finch.request(GitHub.Finch)
  end

  @spec http_post(access_token :: String.t(), url :: String.t(), body :: String.t()) ::
          {:ok, Finch.Response.t()} | {:error, Exception.t()}
  defp http_post(access_token, url, body) when is_binary(access_token) and is_binary(url) do
    Logger.debug("POST #{url}: #{inspect(body)}")

    Finch.build(
      :post,
      url,
      [
        {"Authorization", "Bearer #{access_token}"},
        {"Content-Type", "application/json"},
        {"Accept", "application/json"}
      ],
      body
    )
    |> Finch.request(GitHub.Finch)
  end
end

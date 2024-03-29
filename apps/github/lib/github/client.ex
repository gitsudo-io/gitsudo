defmodule GitHub.Client do
  @moduledoc """
  The low-level GitHub client
  """

  require Logger

  ###########################################################################
  # App Installation
  ###########################################################################

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

  ###########################################################################
  # OAuth
  ###########################################################################

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

  ###########################################################################
  # Organization
  ###########################################################################

  @doc """
  List all the repos under the given organization visible to the given access token.

  ```
    GET /org/{owner}/repos
  ```
  """
  @spec list_org_repos(access_token :: String.t(), org :: String.t()) ::
          {:ok, list()} | {:error, String.t() | Exception.t() | Jason.DecodeError.t()}
  def list_org_repos(access_token, org) do
    http_get_and_decode(access_token, "orgs/#{org}/repos")
  end

  ###########################################################################
  # Repositories
  ###########################################################################

  @doc """
  Get a repository

  ```
    GET /repos/{owner}/{repo}
  ```
  """
  @spec get_repo(access_token :: String.t(), owner :: String.t(), repo :: String.t()) ::
          {:ok, map()} | {:error, String.t() | Exception.t() | Jason.DecodeError.t()}
  def get_repo(access_token, owner, repo),
    do: http_get_and_decode(access_token, "repos/#{owner}/#{repo}")

  @doc """
  Get a repository by id
  """
  @spec get_repository_by_id(access_token :: String.t(), id :: integer()) ::
          {:ok, map()} | {:error, String.t() | Exception.t() | Jason.DecodeError.t()}
  def get_repository_by_id(access_token, id),
    do: http_get_and_decode(access_token, "repositories/#{id}")

  ###########################################################################
  # Collaborators
  ###########################################################################

  @doc """
  Add a repository collaborator.

  See https://docs.github.com/en/rest/collaborators/collaborators#add-a-repository-collaborator
  """
  @spec add_repository_collaborator(
          access_token :: String.t(),
          owner :: String.t(),
          repo :: String.t(),
          username :: String.t(),
          permission :: String.t()
        ) ::
          {:ok, any()} | {:error, String.t() | Exception.t() | Jason.DecodeError.t()}
  def add_repository_collaborator(access_token, owner, repo, username, permission) do
    url = url_for("repos/#{owner}/#{repo}/collaborators/#{username}")
    body = %{"permission" => permission}

    with {:ok, resp} <- http_put(access_token, url, body) do
      if 204 == resp.status do
        {:ok, resp}
      else
        Logger.debug("resp.status: #{resp.status}")
        reason = "#{resp.status} #{Plug.Conn.Status.reason_phrase(resp.status)}"
        Logger.error(reason)
        {:error, reason}
      end
    end
  end

  @doc """
  Remove a repository collaborator.

  See https://docs.github.com/en/rest/collaborators/collaborators#remove-a-repository-collaborator
  """
  @spec remove_repository_collaborator(
          access_token :: String.t(),
          owner :: String.t(),
          repo :: String.t(),
          username :: String.t()
        ) ::
          {:ok, any()} | {:error, String.t() | Exception.t() | Jason.DecodeError.t()}
  def remove_repository_collaborator(access_token, owner, repo, username),
    do: http_delete(access_token, url_for("repos/#{owner}/#{repo}/collaborators/#{username}"))

  ###########################################################################
  # Organization Members
  ###########################################################################

  @doc """
  Get organization membership for a user

  ```
  GET /orgs/{org}/memberships/{username}
  ```
  """
  @spec get_organization_membership(
          access_token :: String.t(),
          org :: String.t(),
          username :: String.t()
        ) :: {:ok, any()} | {:error, String.t() | Exception.t() | Jason.DecodeError.t()}
  def get_organization_membership(access_token, org, username),
    do: http_get_and_decode(access_token, "orgs/#{org}/memberships/#{username}")

  ###########################################################################
  # Teams
  ###########################################################################

  @doc """
  Get a team by slug

  ```
    GET /orgs/{org}/teams/{team_slug}
  ```
  """
  @spec get_team(access_token :: String.t(), org :: String.t(), team_slug :: String.t()) ::
          {:ok, map()} | {:error, String.t() | Exception.t() | Jason.DecodeError.t()}
  def get_team(access_token, org, team_slug),
    do: http_get_and_decode(access_token, "orgs/#{org}/teams/#{team_slug}")

  @doc """
  Check team permissions for a repository

  ```
  GET /orgs/{org}/teams/{team_slug}/repos/{owner}/{repo}
  ```
  """
  @spec get_team_repository_permissions(
          access_token :: String.t(),
          org :: String.t(),
          team_slug :: String.t(),
          owner :: String.t(),
          repo :: String.t()
        ) :: {:ok, map()} | {:error, String.t() | Exception.t() | Jason.DecodeError.t()}
  def get_team_repository_permissions(access_token, org, team_slug, owner, repo),
    do:
      http_get_and_decode(
        access_token,
        "orgs/#{org}/teams/#{team_slug}/repos/#{owner}/#{repo}",
        %{},
        headers: %{"Accept" => "application/vnd.github.v3.repository+json"}
      )

  @doc """
  Add or update team repository permissions

  ```
  PUT /orgs/{org}/teams/{team_slug}/repos/{owner}/{repo}
  ```
  """
  @spec put_team_repository_permissions(
          access_token :: String.t(),
          org :: String.t(),
          team_slug :: String.t(),
          owner :: String.t(),
          repo :: String.t(),
          permission :: String.t()
        ) ::
          {:ok, any()} | {:error, String.t() | Exception.t() | Jason.DecodeError.t()}
  def put_team_repository_permissions(access_token, org, team_slug, owner, repo, permission)
      when is_binary(access_token) and is_binary(org) and is_binary(owner) and is_binary(repo) and
             is_binary(permission) do
    url = url_for("orgs/#{org}/teams/#{team_slug}/repos/#{owner}/#{repo}")
    body = %{"permission" => permission}

    with {:ok, resp} <- http_put(access_token, url, body) do
      if 204 == resp.status do
        {:ok, resp}
      else
        Logger.debug("resp.status: #{resp.status}")
        reason = "#{resp.status} #{Plug.Conn.Status.reason_phrase(resp.status)}"
        Logger.error(reason)
        {:error, reason}
      end
    end
  end

  @doc """
  Remove a repository from a team

  ```
  DELETE /orgs/{org}/teams/{team_slug}/repos/{owner}/{repo}
  ```
  """
  @spec remove_repository_from_team(
          access_token :: String.t(),
          org :: String.t(),
          team_slug :: String.t(),
          owner :: String.t(),
          repo :: String.t()
        ) ::
          {:ok, any()} | {:error, String.t() | Exception.t() | Jason.DecodeError.t()}
  def remove_repository_from_team(access_token, org, team_slug, owner, repo) do
    url = url_for("orgs/#{org}/teams/#{team_slug}/repos/#{owner}/#{repo}")

    with {:ok, resp} <- http_delete(access_token, url) do
      if 204 == resp.status do
        {:ok, resp}
      else
        Logger.debug("resp.status: #{resp.status}")
        reason = "#{resp.status} #{Plug.Conn.Status.reason_phrase(resp.status)}"
        Logger.error(reason)
        {:error, reason}
      end
    end
  end

  ###########################################################################
  # Workflows
  ###########################################################################

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
  Get a workflow

  ```
  GET /repos/{owner}/{repo}/actions/workflows/{workflow_id}
  ```
  """
  @spec get_workflow(
          access_token :: String.t(),
          owner :: String.t(),
          repo :: String.t(),
          workflow_id :: integer()
        ) ::
          {:ok, map()} | {:error, String.t() | Exception.t() | Jason.DecodeError.t()}
  def get_workflow(access_token, owner, repo, workflow_id) do
    http_get_and_decode(access_token, "repos/#{owner}/#{repo}/actions/workflows/#{workflow_id}")
  end

  @default_per_page 30

  @doc """
  List workflow runs for a given repository

  ```
    GET /repos/{owner}/{repo}/actions/runs
  ```
  """
  @spec list_workflow_runs(
          access_token :: String.t(),
          owner :: String.t(),
          repo :: String.t(),
          opts :: Keyword.t()
        ) ::
          {:ok, map()} | {:error, String.t() | Exception.t() | Jason.DecodeError.t()}
  def list_workflow_runs(access_token, owner, repo, opts \\ []) do
    path = "repos/#{owner}/#{repo}/actions/runs"
    params = %{"page" => Keyword.get(opts, :page, 1)}
    http_get_and_decode(access_token, path, params)
  end

  @doc """
  List all workflow runs for a given repository. Calls Client.list_workflow_runs/4
  repeatedly until all pages have been retrieved.

  ```
    GET /repos/{owner}/{repo}/actions/runs
  ```
  """
  @spec list_all_workflow_runs(
          access_token :: String.t(),
          owner :: String.t(),
          repo :: String.t()
        ) ::
          {:ok, map()} | {:error, String.t() | Exception.t() | Jason.DecodeError.t()}
  def list_all_workflow_runs(access_token, owner, repo) do
    with {:ok, init} <- list_workflow_runs(access_token, owner, repo) do
      if init["total_count"] > @default_per_page do
        list_rest_of_workflow_runs(access_token, owner, repo, init, 2)
      else
        {:ok, init}
      end
    end
  end

  defp list_rest_of_workflow_runs(access_token, owner, repo, list, page) do
    with {:ok, rest} <- list_workflow_runs(access_token, owner, repo, page: page) do
      result = combine_workflow_run_results(list, rest)

      if list["total_count"] > page * @default_per_page do
        list_rest_of_workflow_runs(access_token, owner, repo, result, page + 1)
      else
        {:ok, result}
      end
    end
  end

  defp combine_workflow_run_results(init, rest) do
    init_workflow_runs = init["workflow_runs"]
    rest_workflow_runs = rest["workflow_runs"]

    init
    |> Map.delete("workflow_runs")
    |> Map.put("workflow_runs", init_workflow_runs ++ rest_workflow_runs)
  end

  @doc """
  Get a workflow run

  ```
  GET /repos/{owner}/{repo}/actions/runs/{run_id}
  ```
  """
  @spec get_workflow_run(
          access_token :: String.t(),
          owner :: String.t(),
          repo :: String.t(),
          run_id :: integer()
        ) ::
          {:ok, map()} | {:error, String.t() | Exception.t() | Jason.DecodeError.t()}
  def get_workflow_run(access_token, owner, repo, run_id) do
    http_get_and_decode(access_token, "repos/#{owner}/#{repo}/actions/runs/#{run_id}")
  end

  @doc """
  Fetches all workflow runs for a given repository, and calls the given function with each page of results.
  The given function _must_ accept `(acc, page)` and return either `{:cont, acc}` or `{:halt, acc}`
  (similar to &Enum.reduce_while/3).

  Calls Client.list_workflow_runs/4 to retrieve each page.

  ```
    GET /repos/{owner}/{repo}/actions/runs
  ```
  """
  @spec with_all_workflow_runs(
          access_token :: String.t(),
          owner :: String.t(),
          repo :: String.t(),
          acc :: any,
          fun :: function()
        ) ::
          {:ok, list()} | {:error, String.t() | Exception.t() | Jason.DecodeError.t()}
  def with_all_workflow_runs(access_token, owner, repo, acc, fun) do
    with {:ok, results} <- list_workflow_runs(access_token, owner, repo) do
      case apply(fun, [results, acc]) do
        {:cont, new_acc} ->
          if results["total_count"] > @default_per_page do
            with_rest_of_workflow_runs(access_token, owner, repo, 2, new_acc, fun)
          else
            new_acc
          end

        {:halt, new_acc} ->
          new_acc
      end
    end
  end

  defp with_rest_of_workflow_runs(access_token, owner, repo, page, acc, fun) do
    with {:ok, results} <- list_workflow_runs(access_token, owner, repo, page: page) do
      case apply(fun, [results, acc]) do
        {:cont, new_acc} ->
          if results["total_count"] > page * @default_per_page do
            with_rest_of_workflow_runs(access_token, owner, repo, page + 1, new_acc, fun)
          else
            new_acc
          end

        {:halt, new_acc} ->
          new_acc
      end
    end
  end

  @spec list_workflow_run_jobs(
          access_token :: String.t(),
          owner :: String.t(),
          repo :: String.t(),
          run_id :: integer()
        ) ::
          {:ok, map()} | {:error, String.t() | Exception.t() | Jason.DecodeError.t()}
  def list_workflow_run_jobs(access_token, owner, repo, run_id) do
    http_get_and_decode(access_token, "repos/#{owner}/#{repo}/actions/runs/#{run_id}/jobs")
  end

  ###########################################################################
  # Users
  ###########################################################################

  @doc """
  Get the user.

  ```
    GET /user
  ```
  """
  @spec get_user(access_token :: String.t(), login :: String.t()) ::
          {:ok, map()} | {:error, String.t() | Exception.t() | Jason.DecodeError.t()}
  def get_user(access_token, login),
    do: http_get_and_decode(access_token, "users/#{login}")

  ###########################################################################
  # User scope
  ###########################################################################

  @doc """
  Get the logged in user associated with an access token, if available.

  ```
    GET /user
  ```
  """
  @spec get_user(binary) ::
          {:ok, map()} | {:error, String.t() | Exception.t() | Jason.DecodeError.t()}
  def get_user(access_token), do: http_get_and_decode(access_token, "user")

  @doc """
  List app installations accessible to the user access token

  See: https://docs.github.com/en/rest/apps/installations?apiVersion=2022-11-28#list-app-installations-accessible-to-the-user-access-token

  ```
    GET /user/installations
  ```
  """
  @spec list_user_installations(access_token :: String.t()) ::
          {:ok, map()} | {:error, String.t() | Exception.t() | Jason.DecodeError.t()}
  def list_user_installations(access_token),
    do: http_get_and_decode(access_token, "user/installations")

  @doc """
  ```
    GET /user/repos
  ```
  """
  @spec list_user_repositories(binary) ::
          {:ok, map()} | {:error, String.t() | Exception.t() | Jason.DecodeError.t()}
  def list_user_repositories(access_token), do: http_get_and_decode(access_token, "user/repos")

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

  ###########################################################################
  # Helper functions
  ###########################################################################

  defp url_for(path, params \\ %{}) do
    base_url =
      if String.starts_with?(path, "/") do
        "https://api.github.com"
      else
        "https://api.github.com/"
      end

    if Enum.empty?(params) do
      "#{base_url}#{path}"
    else
      "#{base_url}#{path}?#{encode_query_parameters(params)}"
    end
  end

  @spec http_get_and_decode(access_token :: String.t(), path :: String.t(), params :: map()) ::
          {:ok, any} | {:error, String.t() | Exception.t() | Jason.DecodeError.t()}
  defp http_get_and_decode(access_token, path, params \\ %{}, opts \\ [])
       when is_binary(access_token) and is_binary(path) and is_map(params) do
    with {:ok, resp} <- http_get_api(access_token, path, params, opts) do
      if 200 == resp.status do
        Jason.decode(resp.body)
      else
        Logger.debug("resp.status: #{resp.status}")
        {:error, "#{resp.status} #{Plug.Conn.Status.reason_phrase(resp.status)}"}
      end
    end
  end

  @doc """
  URI encode parameters and return them as a query string.
  """
  @spec encode_query_parameters(params :: map()) :: String.t()
  def encode_query_parameters(params) do
    params |> Enum.map_join("&", fn {k, v} -> "#{encode(k)}=#{encode(v)}" end)
  end

  defp encode(t), do: URI.encode(to_string(t))

  @default_get_headers_map %{
    "Content-Type" => "application/json",
    "Accept" => "application/vnd.github+json"
  }

  # Construct an HTTPoison.get request to the given path with the given access token
  # as the `Authorization: Bearer` token.
  @spec http_get_api(
          access_token :: String.t(),
          path :: String.t(),
          params :: map(),
          opts :: keyword()
        ) ::
          {:ok, Finch.Response.t()} | {:error, Exception.t()}
  defp http_get_api(access_token, path, params \\ %{}, opts \\ [])
       when is_binary(access_token) and
              is_binary(path) and is_map(params) do
    url = url_for(path, params)
    Logger.debug("GET #{url}")

    headers = build_get_headers(opts)

    Finch.build(:get, url, [
      {"Authorization", "Bearer #{access_token}"}
      | headers
    ])
    |> Finch.request(GitHub.Finch)
  end

  def build_get_headers(headers: headers) do
    headers
    |> Enum.reduce(@default_get_headers_map, fn {k, v}, headers ->
      Map.put(headers, to_string(k), v)
    end)
    |> Map.to_list()
  end

  def build_get_headers(_), do: Map.to_list(@default_get_headers_map)

  defp http_put(access_token, url, body)
       when is_binary(access_token) and is_binary(url) and is_map(body) do
    with {:ok, encoded} <- Jason.encode(body) do
      http_put(access_token, url, encoded)
    end
  end

  defp http_put(access_token, url, body)
       when is_binary(access_token) and is_binary(url) and is_binary(body) do
    Logger.debug("PUT #{url}: #{inspect(body)}")

    Finch.build(
      :put,
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

  defp http_delete(access_token, url) when is_binary(access_token) and is_binary(url) do
    Logger.debug("DELETE #{url}")

    Finch.build(:delete, url, [{"Authorization", "Bearer #{access_token}"}])
    |> Finch.request(GitHub.Finch)
  end
end

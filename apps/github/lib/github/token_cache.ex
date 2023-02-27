defmodule GitHub.TokenCache do
  @moduledoc """
  Caches GitHub app installation tokens
  """
  alias ExActor.GenServer
  use GenServer

  require Logger

  @spec start_link([{:app_id, integer()} | {:key_pem, String.t()}]) ::
          :ignore | {:error, any} | {:ok, pid}
  def start_link(app_id: app_id, key_pem: key_pem) do
    Logger.debug("app_id: #{app_id}")
    signer = Joken.Signer.create("RS256", %{"pem" => key_pem})
    Logger.debug("key_thumprint: #{JOSE.JWK.thumbprint(signer.jwk)}")
    GenServer.start_link(__MODULE__, [app_id: app_id, signer: signer], name: __MODULE__)
  end

  @impl true
  @spec init([{:app_id, integer()} | {:signer, Joken.Signer.t()}]) ::
          {:ok, {[{:app_id, integer()} | {:signer, Joken.Signer.t()}], %{}}}
  def init([app_id: app_id, signer: signer] = args) do
    Logger.debug("app_id: #{app_id}")
    Logger.debug("key_thumprint: #{JOSE.JWK.thumbprint(signer.jwk)}")
    {:ok, {args, %{}}}
  end

  @impl true
  def handle_call(request, from, state) do
    case request do
      {:get, installation_id} ->
        do_get(installation_id, state)

      {:get_or_refresh, installation_id} ->
        do_get_or_refresh(installation_id, state)

      _ ->
        {:reply, {:error, "Unrecognized request #{inspect(request)} from #{from}!"}, state}
    end
  end

  @spec do_get(
          installation_id :: integer(),
          args :: {[{:app_id, String.t()} | {:signer, Joken.Signer.t()}], cache :: map()}
        ) ::
          {:reply, {:ok, String.t()},
           {[{:app_id, String.t()} | {:signer, Joken.Signer.t()}], map()}}
  def do_get(installation_id, {[app_id: app_id, signer: signer] = args, cache}) do
    Logger.debug("app_id: #{app_id}")
    Logger.debug("key_thumprint: #{JOSE.JWK.thumbprint(signer.jwk)}")

    with {:ok, token} <- get_token_and_check_expiry(cache, installation_id) do
      {:reply, {:ok, token}, {args, cache}}
    else
      nil -> {:reply, {:error, "No value for installation id #{installation_id}"}, {args, cache}}
    end
  end

  @spec do_get_or_refresh(
          installation_id :: integer(),
          args :: {[{:app_id, String.t()} | {:signer, Joken.Signer.t()}], cache :: map()}
        ) ::
          {:reply, {:ok, String.t()},
           {[{:app_id, String.t()} | {:signer, Joken.Signer.t()}], map()}}
  def do_get_or_refresh(
        installation_id,
        {[app_id: app_id, signer: signer] = args, cache}
      ) do
    Logger.debug("app_id: #{app_id}")
    Logger.debug("key_thumprint: #{JOSE.JWK.thumbprint(signer.jwk)}")

    with {:ok, token} <- get_token_and_check_expiry(cache, installation_id) do
      {:reply, {:ok, token}, {args, cache}}
    else
      nil -> fetch_new_token(args, cache, installation_id)
    end
  end

  defp get_token_and_check_expiry(cache, installation_id) do
    Logger.debug("installation_id: #{installation_id}")

    with {:ok, [token: token, expiry: expiry]} <- Map.fetch(cache, installation_id) do
      if :os.system_time(:second) < expiry do
        {:ok, token}
      else
        nil
      end
    else
      :error -> nil
    end
  end

  defp fetch_new_token([app_id: app_id, signer: signer] = args, cache, installation_id) do
    Logger.debug("app_id: #{app_id}")
    Logger.debug("key_thumprint: #{JOSE.JWK.thumbprint(signer.jwk)}")
    Logger.debug("installation_id: #{installation_id}")

    # TODO: Fetch from database or something
    url = "https://api.github.com/app/installations/#{installation_id}/access_tokens"

    Logger.debug("access_tokens_url: #{url}")

    with {:ok, resp} <-
           GitHub.Client.get_app_installation_access_token_with_signer(app_id, signer, url) do
      token = resp["token"]
      # expire after 59 minutes
      expiry = :os.system_time(:second) + 59 * 60
      value = [token: token, expiry: expiry]

      new_map = Map.put(cache, installation_id, value)
      Logger.debug("{:reply, {:ok, #{inspect(token)}, {#{inspect(args)}, #{inspect(new_map)}}")
      {:reply, {:ok, token}, {args, new_map}}
    else
      {:error, reason} ->
        Logger.error(reason)
        {:reply, {:error, reason}, {args, cache}}
    end
  end

  @spec get_token(installation_id :: integer()) :: {:ok, String.t()} | {:error, any}
  def get_token(installation_id) do
    GenServer.call(__MODULE__, {:get, installation_id})
  end

  @spec get_or_refresh_token(installation_id :: integer()) :: {:ok, String.t()} | {:error, any}
  def get_or_refresh_token(installation_id) do
    GenServer.call(__MODULE__, {:get_or_refresh, installation_id})
  end
end

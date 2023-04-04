defmodule Gitsudo.Workflows do
  @moduledoc """
  The Workflows context.
  """
  import Ecto.Query, warn: false

  require Logger

  @spec list_workflow_runs(binary, any, any) ::
          {:error,
           nonempty_binary | %{:__exception__ => true, :__struct__ => atom, optional(atom) => any}}
          | {:ok, any}
  def list_workflow_runs(access_token, organization, repository) do
    case GitHub.Client.list_workflow_runs(access_token, organization, repository) do
      {:ok, data} ->
        Logger.debug(
          ~s'Found #{data["total_count"]} workflow runs for "#{organization}/#{repository}"'
        )

        {:ok, data["workflow_runs"]}

      {:error, reason} ->
        {:error, reason}
    end
  end
end

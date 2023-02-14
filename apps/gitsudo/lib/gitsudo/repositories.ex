defmodule Gitsudo.Repositories do
  @moduledoc """
  The Repositories context.
  """

  import Ecto.Query, warn: false
  alias Gitsudo.Repo

  alias Gitsudo.Repositories.{Repository, Owner}

  @doc """
  Get repository by owner_id and name
  """
  def get_repository_by_owner_id_and_name(owner_id, name) do
    Repo.get_by(Repository, owner_id: owner_id, name: name)
  end
end

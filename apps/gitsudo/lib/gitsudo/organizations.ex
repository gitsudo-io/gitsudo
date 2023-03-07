defmodule Gitsudo.Organizations do
  @moduledoc """
  The Organizations context.
  """

  import Ecto.Query, warn: false

  alias Gitsudo.Repo

  require Logger

  def get_organization(name) do
    Repo.get_by(Gitsudo.Accounts.Account, type: "Organization", login: name)
  end
end

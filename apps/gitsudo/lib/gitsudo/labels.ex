defmodule Gitsudo.Labels do
  @moduledoc """
  The Labels context.
  """
  alias Gitsudo.Repo
  alias Gitsudo.Labels.Label

  import Ecto.Query, warn: false

  require Logger

  @doc """
  Returns the labels for an organization.

  ## Examples

      iex> list_labels(org)
      [%Label{}, ...]

  """
  def list_organization_labels(owner_id) do
    query = from l in Label, where: l.owner_id == ^owner_id
    Repo.all(query)
  end

  @doc """
  Retrieves a single organization label by id
  """
  def get_label!(owner_id, id, opts \\ []) do
    label = Repo.get_by!(Label, owner_id: owner_id, id: id)

    if Keyword.has_key?(opts, :preload) do
      Repo.preload(label, opts[:preload])
    else
      label
    end
  end

  @doc """
  Retrieves a single organization label by name
  """
  @spec get_label_by_name(owner_id :: integer(), name :: String.t()) :: Ecto.Schema.t() | term()
  def get_label_by_name(owner_id, name),
    do:
      Repo.get_by(Label, owner_id: owner_id, name: name)
      |> Repo.preload([
        :owner,
        :repositories,
        :team_policies,
        collaborator_policies: [:collaborator]
      ])

  @doc """
  Creates a label.

  ## Examples

      iex> create_label(42, %{field: value})
      {:ok, %Label{}}

      iex> create_label(42, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  @spec create_label(
          integer(),
          map()
        ) :: {:ok, Ecto.Schema.t()} | {:error, Ecto.Changeset.t()}
  def create_label(owner_id, attrs, opts \\ []) do
    with {:ok, label} <-
           %Label{
             owner_id: owner_id
           }
           |> Label.changeset(attrs)
           |> Repo.insert() do
      {:ok,
       if Keyword.has_key?(opts, :preload) do
         Repo.preload(label, opts[:preload])
       else
         label
       end}
    end
  end

  @doc """
  Updates a label.

  ## Examples

      iex> update_label(label, %{field: new_value})
      {:ok, %Label{}}

      iex> update_label(label, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_label(%Label{} = label, attrs, opts \\ []) do
    with {:ok, label} <-
           label
           |> Label.changeset(attrs)
           |> Repo.update() do
      {:ok,
       if Keyword.has_key?(opts, :preload) do
         Repo.preload(label, opts[:preload])
       else
         label
       end}
    end
  end

  @doc """
  Deletes a label.

  ## Examples

      iex> delete_label(label)
      {:ok, %Label{}}

      iex> delete_label(label)
      {:error, %Ecto.Changeset{}}

  """
  def delete_label(%Label{} = label) do
    Repo.delete(label)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking label changes.

  ## Examples

      iex> change_label(label)
      %Ecto.Changeset{data: %Label{}}

  """
  def change_label(%Label{} = label, attrs \\ %{}) do
    Label.changeset(label, attrs)
  end
end

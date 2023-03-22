defmodule Gitsudo.Labels do
  @moduledoc """
  The Labels context.
  """
  alias Gitsudo.Repo
  alias Gitsudo.Labels.Label

  import Ecto.Query, warn: false

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
  def get_label!(owner_id, id),
    do: Repo.get_by!(Label, owner_id: owner_id, id: id)

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
  def create_label(owner_id, attrs) do
    %Label{
      owner_id: owner_id
    }
    |> Label.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a label.

  ## Examples

      iex> update_label(label, %{field: new_value})
      {:ok, %Label{}}

      iex> update_label(label, %{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def update_label(%Label{} = label, attrs) do
    label
    |> Label.changeset(attrs)
    |> Repo.update()
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

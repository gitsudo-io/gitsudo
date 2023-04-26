defmodule GitsudoWeb.API.LabelJSON do
  @moduledoc """
  The JSON 'views' for labels
  """

  alias Gitsudo.Labels.Label

  @doc """
  Renders a list of labels.
  """
  @spec index(%{:labels => list, optional(any) => any}) :: %{data: list}
  def index(%{labels: labels}) do
    %{data: for(label <- labels, do: data(label))}
  end

  @doc """
  Renders a single label.
  """
  @spec show(%{
          :label => map(),
          optional(any) => any
        }) :: %{
          data: %{color: any, id: any, name: any, owner_id: any, collaborator_policies: list()}
        }
  def show(%{label: label}) do
    %{data: data(label)}
  end

  defp data(%Label{} = label) do
    %{
      id: label.id,
      owner_id: label.owner_id,
      name: label.name,
      color: label.color,
      collaborator_policies: label.collaborator_policies
    }
  end
end

defmodule GitsudoWeb.LabelJSON do
  @moduledoc """
  The Labels JSON API controller
  """
  use GitsudoWeb, :controller

  alias Gitsudo.Labels.Label

  @doc """
  Renders a list of labels.
  """
  def index(%{labels: labels}) do
    %{data: for(label <- labels, do: data(label))}
  end

  @doc """
  Renders a single label.
  """
  def show(%{label: label}) do
    %{data: data(label)}
  end

  defp data(%Label{} = label) do
    %{
      id: label.id,
      owner_id: label.owner_id,
      name: label.name,
      color: label.color
    }
  end
end

defmodule Gitsudo.LabelsFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `Gitsudo.Labels` context.
  """

  @doc """
  Generate a label.
  """
  def label_fixture(attrs \\ %{}) do
    create_attrs =
      attrs
      |> Enum.into(%{
        color: "label-red",
        name: "backend"
      })

    {:ok, label} = Gitsudo.Labels.create_label(121_780_924, create_attrs)

    label
  end
end

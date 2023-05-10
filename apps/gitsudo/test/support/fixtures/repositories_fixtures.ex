defmodule Gitsudo.RepositoriesFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `Gitsudo.Repositories` context.
  """

  @doc """
  Generate a label.
  """
  def repository_fixture(attrs \\ %{}) do
    create_attrs =
      attrs
      |> Enum.into(%{
        id: 621_016_081,
        owner: %{
          id: 121_780_924
        },
        name: "test-repo-alpha",
        html_url: "https://github.com/gitsudo-io/test-repo-alpha"
      })
      # transform keys to strings :p
      |> Jason.encode!()
      |> Jason.decode!()

    {:ok, repo} = Gitsudo.Repositories.create_repository(create_attrs, preload: [:labels])

    repo
  end
end

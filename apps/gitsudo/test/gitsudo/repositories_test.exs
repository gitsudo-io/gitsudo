defmodule Gitsudo.RepositoriesTest do
  use Gitsudo.DataCase

  alias Gitsudo.Repositories

  import Gitsudo.RepositoriesFixtures

  @owner_id 121_780_924

  setup do
    {:ok, account} =
      Gitsudo.Accounts.find_or_create_account(@owner_id, %{
        "login" => "gitsudo-io",
        "type" => "Organization"
      })

    repository = repository_fixture(%{owner: %{id: account.id}})

    {:ok, repository: repository}
  end

  describe "labels" do
    import Gitsudo.LabelsFixtures

    test "add_label_to_repository works", %{repository: repository} do
      assert repository.labels == []

      label = label_fixture()
      {:ok, repository} = Repositories.add_label_to_repository(repository, label)

      assert repository.labels == [label]
    end
  end
end

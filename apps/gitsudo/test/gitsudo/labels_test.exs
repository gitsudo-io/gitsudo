defmodule Gitsudo.LabelsTest do
  use Gitsudo.DataCase

  alias Gitsudo.Labels

  @owner_id 121_780_924

  setup do
    {:ok, _account} =
      Gitsudo.Accounts.find_or_create_account(@owner_id, %{
        "login" => "gitsudo-io",
        "type" => "Organization"
      })

    :ok
  end

  describe "labels" do
    alias Gitsudo.Labels.Label

    import Gitsudo.LabelsFixtures

    @invalid_attrs %{color: nil, name: nil}

    test "list_labels/0 returns all labels" do
      label = label_fixture()

      assert Labels.list_organization_labels(@owner_id) == [
               Labels.get_label!(@owner_id, label.id)
             ]
    end

    test "get_label!/1 returns the label with given id" do
      label = label_fixture()
      assert Labels.get_label!(@owner_id, label.id, preload: [:owner]) == label
    end

    test "create_label/1 with valid data creates a label" do
      valid_attrs = %{color: "some color", name: "some name"}

      assert {:ok, %Label{} = label} = Labels.create_label(@owner_id, valid_attrs)
      assert label.color == "some color"
      assert label.name == "some name"
    end

    test "create_label/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Labels.create_label(@owner_id, @invalid_attrs)
    end

    test "update_label/2 with valid data updates the label" do
      label = label_fixture()
      update_attrs = %{color: "some updated color", name: "some updated name"}

      assert {:ok, %Label{} = label} = Labels.update_label(label, update_attrs)
      assert label.color == "some updated color"
      assert label.name == "some updated name"
    end

    test "update_label/2 with invalid data returns error changeset" do
      label = label_fixture()
      assert {:error, %Ecto.Changeset{}} = Labels.update_label(label, @invalid_attrs)
      assert label == Labels.get_label!(@owner_id, label.id, preload: [:owner])
    end

    test "delete_label/1 deletes the label" do
      label = label_fixture()
      assert {:ok, %Label{}} = Labels.delete_label(label)
      assert_raise Ecto.NoResultsError, fn -> Labels.get_label!(@owner_id, label.id) end
    end

    test "change_label/1 returns a label changeset" do
      label = label_fixture()
      assert %Ecto.Changeset{} = Labels.change_label(label)
    end
  end
end

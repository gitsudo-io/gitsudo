defmodule Foo do
  defstruct [:id, :name]
end

defmodule MapUtilsTest do
  use ExUnit.Case, async: true

  describe "MapUtils.from_enum/2" do
    test "it works with 1-arity function that just returns the key" do
      array = [
        %Foo{id: 1, name: "foo"},
        %Foo{id: 2, name: "bar"}
      ]

      map = MapUtils.from_enum(array, & &1.name)
      assert %{"foo" => %Foo{id: 1, name: "foo"}, "bar" => %Foo{id: 2, name: "bar"}} = map
    end

    test "it works with a 2-arity function that receives the element and the initial map" do
      array = [
        %Foo{id: 1, name: "foo"},
        %Foo{id: 2, name: "bar"}
      ]

      map =
        MapUtils.from_enum(array, fn elem, acc ->
          Map.put(acc, elem.name, elem.id)
        end)

      assert %{"foo" => 1, "bar" => 2} = map
    end
  end

  test "MapUtils.delta/2 works" do
    {%{}, %{}, %{}} = MapUtils.delta(%{}, %{})
    {%{"a" => 1}, %{}, %{}} = MapUtils.delta(%{"a" => 1}, %{})
    {%{}, %{}, %{"b" => 2}} = MapUtils.delta(%{}, %{"b" => 2})
    {%{"a" => 1}, %{}, %{"b" => 2}} = MapUtils.delta(%{"a" => 1}, %{"b" => 2})
    {%{}, %{"c" => 3}, %{}} = MapUtils.delta(%{"c" => 0}, %{"c" => 3})

    {%{"a" => 1}, %{"c" => 3}, %{"b" => 2}} =
      MapUtils.delta(%{"a" => 1, "c" => 0}, %{"b" => 2, "c" => 3})
  end
end

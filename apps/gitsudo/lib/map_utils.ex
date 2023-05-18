defmodule MapUtils do
  @moduledoc """
  A set of generic utility functions dealing with Maps.
  """

  @doc """
  Transforms an enumerable into a map, using the given function to map each element to the map key.
  """
  def from_enum(enumerable, fun), do: from_enum(enumerable, %{}, fun)

  def from_enum(enumerable, init, fun) when is_map(init) and is_function(fun, 1),
    do:
      Enum.reduce(enumerable, init, fn elem, acc ->
        Map.put(acc, fun.(elem), elem)
      end)

  def from_enum(enumerable, init, fun) when is_map(init) and is_function(fun, 2),
    do:
      Enum.reduce(enumerable, init, fn elem, acc ->
        fun.(elem, acc)
      end)

  @doc """
  Transforms an enumerable into a map, using the first function to map each element to the map key and the second
  function to map each element to the corresponding value.
  """
  def from_enum(enumerable, key_fun, value_fun)
      when is_function(key_fun, 1) and is_function(value_fun, 1),
      do: from_enum(enumerable, %{}, key_fun, value_fun)

  def from_enum(enumerable, init, key_fun, value_fun)
      when is_function(key_fun, 1) and is_function(value_fun, 1),
      do:
        Enum.reduce(enumerable, init, fn elem, acc ->
          Map.put(acc, key_fun.(elem), value_fun.(elem))
        end)

  @doc """
  Computes the delta (`{left, common, right}`) between two maps, where:

  - `left` is a map with keys that are in the first map but not in the second
  - `common` is a map with keys that are in both maps, but the value is the value from the second
  - `right` is a map with keys that are in the second map but not in the first
  """
  def delta(first, second) when is_map(first) and is_map(second) do
    left = Map.drop(first, Map.keys(second))
    common = Map.take(second, Map.keys(first))
    right = Map.drop(second, Map.keys(first))

    {left, common, right}
  end
end

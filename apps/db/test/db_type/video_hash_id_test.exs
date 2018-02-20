defmodule DB.Type.VideoHashIdTest do
  use ExUnit.Case
  use ExUnitProperties

  alias DB.Type.VideoHashId

  doctest VideoHashId

  @nb_ids_to_test 1_000

  @tag timeout: 3600_000
  test "ensure there is no collision" do
    start = 1
    range = start..(start + @nb_ids_to_test)

    uniq_generated_ids =
      range
      |> Enum.map(&VideoHashId.encode/1)
      |> Enum.into(MapSet.new)

    assert Enum.count(uniq_generated_ids) == Enum.count(range)
  end

  property "should work with any integer" do
    check all id <- id_generator(),
      do: assert String.length(VideoHashId.encode(id)) >= 4
  end

  defp id_generator do
    ExUnitProperties.gen all id <- integer() do
      abs(id)
    end
  end
end

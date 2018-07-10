defmodule CF.UtilsTest do
  use ExUnit.Case
  doctest CF.Utils

  describe "map_string_keys_to_atom_keys" do
    test "convert map recursively" do
      base_map = %{
        "test" => %{
          "hello" => :ok
        },
        "test2" => :ok
      }
      expected_map = %{
        test: %{
          hello: :ok
        },
        test2: :ok
      }
      assert CF.Utils.map_string_keys_to_atom_keys(base_map) == expected_map
    end

    test "works with empty map" do
      assert CF.Utils.map_string_keys_to_atom_keys(%{}) == %{}
    end

    test "doesn't crash if binary and atom keys are mixed" do
      base_map = %{
        "test" => %{
          hello: 42
        },
        test_again: :ok
      }
      expected_map = %{
        test: %{
          hello: 42
        },
        test_again: :ok
      }
      assert CF.Utils.map_string_keys_to_atom_keys(base_map) == expected_map
    end
  end
end

defmodule SeedWithCSV do
  def seed(filename, columns_mapping, insert_func) do
    File.stream!(filename)
    |> CSV.decode(headers: true)
    |> Enum.map(&Task.async(fn -> build_and_insert(&1, columns_mapping, insert_func) end))
    |> Enum.map(&Task.await(&1, 30000))
  end

  defp build_and_insert(entry, columns_mapping, insert_func) do
    changes =
      entry
      |> Enum.filter(fn ({key, _}) -> Map.has_key?(columns_mapping, key) end)
      |> Enum.map(fn ({key, value}) -> {Map.get(columns_mapping, key), value} end)
      |> Enum.into(%{})

    insert_func.(changes)
  end
end


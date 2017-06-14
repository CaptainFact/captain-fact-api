defmodule SeedWithCSV do
  @nb_threads 2
  @timeout 60000

  def seed(filename, columns_mapping, insert_func) do
    File.stream!(filename)
    |> CSV.decode(headers: true)
    |> Task.async_stream(
        &build_and_insert(&1, columns_mapping, insert_func),
        max_concurrency: @nb_threads, timeout: @timeout
      )
    |> Enum.to_list()
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


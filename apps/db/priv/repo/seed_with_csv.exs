defmodule SeedWithCSV do
  require Logger

  @nb_threads 1
  @timeout 60_000

  def seed(filename, insert_func, insert_func_args, columns_mapping) do
    if File.exists?(filename),
      do: do_seed(filename, insert_func, insert_func_args, columns_mapping),
      else: Logger.error("File #{filename} doesn't exists")
  end

  defp do_seed(filename, insert_func, insert_func_args, columns_mapping) do
    filename
    |> File.stream!()
    |> CSV.decode(headers: true)
    |> Task.async_stream(
      &build_and_insert(&1, insert_func, insert_func_args, columns_mapping),
      max_concurrency: @nb_threads,
      timeout: @timeout
    )
    |> Enum.to_list()
  end

  defp build_and_insert(entry, insert_func, insert_func_args, columns_mapping) do
    changes =
      entry
      |> Enum.filter(fn {key, _} -> Map.has_key?(columns_mapping, key) end)
      |> Enum.map(fn {key, value} ->
        case Map.get(columns_mapping, key) do
          key when is_atom(key) or is_binary(key) ->
            {key, value}

          {key, func} when is_atom(key) or (is_binary(key) and is_function(func)) ->
            {key, func.(value)}
        end
      end)
      |> Enum.into(%{})

    insert_func.(changes, insert_func_args)
  end
end

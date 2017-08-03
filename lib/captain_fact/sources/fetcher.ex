defmodule CaptainFact.Sources.Fetcher do

  alias CaptainFact.Comments.Comment
  alias CaptainFact.Sources.Fetcher

  # TODO Pool https://elixirschool.com/en/lessons/libraries/poolboy/

  @name __MODULE__
  @pool_name :source_fetcher_pool

  # Public API

  def start_link(), do: Agent.start_link(fn -> MapSet.new end, name: @name)

  @doc """
  Fetch given url infos
  """
  def fetch_source_metadata(url, callback) do
    Agent.get_and_update(@name, fn state ->
      if MapSet.member?(state, url) do
        {:error, state} # Already queued for fetch
      else
        Agent.cast(@name, fn state ->
          callback.(do_fetch_source_metadata(url)) # TODO Send to pool
          MapSet.delete(state, url)
        end)
        {:ok, MapSet.put(state, url)}
      end
    end)
  end

  def get_queue, do: Agent.get(@name, &(&1))

  # Private methods

  defp do_fetch_source_metadata(url) do
    case HTTPoison.get(url, [], [follow_redirect: true, max_redirect: 5]) do
      {:ok, %HTTPoison.Response{status_code: 200, body: body}} ->
        {:ok, source_params_from_tree(Floki.parse(body))}
      {:ok, %HTTPoison.Response{status_code: 404}} ->
        {:error, :not_found}
      {:ok, %HTTPoison.Response{status_code: _}} ->
        {:error, :unknown}
      {:error, %HTTPoison.Error{reason: reason}} ->
        {:error, reason}
    end
  end

  defp source_params_from_tree(tree) do
    %{
      title: Floki.attribute(tree, "meta[property='og:title']", "content"),
      language: Floki.attribute(tree, "html", "lang"),
      site_name: Floki.attribute(tree, "meta[property='og:site_name']", "content"),
      url: Floki.attribute(tree, "meta[property='og:url']", "content")
    }
    |> Enum.map(fn({key, values}) -> {key, List.first(values)} end) # Only first entry
    |> Enum.filter(fn({_, value}) -> value != nil end)
    |> Enum.map(fn(entry = {key, value}) ->
      if key in [:title, :site_name],
        do: {key, HtmlEntities.decode(value)},
        else: entry
      end)
    |> Enum.into(%{})
  end
end
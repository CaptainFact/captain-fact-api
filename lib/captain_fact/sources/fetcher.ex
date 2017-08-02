defmodule CaptainFact.Sources.Fetcher do

  alias CaptainFactWeb.{Comment}

  # TODO Comment updater
  # TODO Pool

  def fetch_source_metadata(url) do
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
defmodule CF.Videos.MetadataFetcher.Opengraph do
  @moduledoc """
  Methods to fetch metadata (title, language) from videos
  """

  @behaviour CF.Videos.MetadataFetcher

  @doc """
  Fetch metadata from video using OpenGraph tags.
  """
  def fetch_video_metadata(url) do
    case HTTPoison.get(url) do
      {:ok, %HTTPoison.Response{body: body}} ->
        meta = Floki.attribute(body, "meta[property='og:title']", "content")

        case meta do
          [] -> {:error, "Page does not contains an OpenGraph title attribute"}
          [title] -> {:ok, %{title: HtmlEntities.decode(title), url: url}}
        end

      {_, _} ->
        {:error, "Remote URL didn't respond correctly"}
    end
  end
end

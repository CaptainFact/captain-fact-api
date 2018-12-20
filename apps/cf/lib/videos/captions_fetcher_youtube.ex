defmodule CF.Videos.CaptionsFetcherYoutube do
  @moduledoc """
  A captions fetcher for YouTube.
  """

  @behaviour CF.Videos.CaptionsFetcher

  @impl true
  def fetch(%{youtube_id: youtube_id, locale: locale}) do
    with {:ok, content} <- fetch_captions_content(youtube_id, locale) do
      captions = %DB.Schema.VideoCaption{
        content: content,
        format: "xml"
      }

      {:ok, captions}
    end
  end

  defp fetch_captions_content(video_id, locale) do
    case HTTPoison.get("http://video.google.com/timedtext?lang=#{locale}&v=#{video_id}") do
      {:ok, %HTTPoison.Response{status_code: 200, body: ""}} ->
        {:error, :not_found}

      {:ok, %HTTPoison.Response{status_code: 200, body: body}} ->
        {:ok, body}

      {:ok, %HTTPoison.Response{status_code: 404}} ->
        {:error, :not_found}

      {:ok, %HTTPoison.Response{status_code: _}} ->
        {:error, :unknown}

      {:error, %HTTPoison.Error{reason: reason}} ->
        {:error, reason}
    end
  end
end

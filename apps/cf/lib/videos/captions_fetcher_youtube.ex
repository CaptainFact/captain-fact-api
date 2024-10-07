defmodule CF.Videos.CaptionsFetcherYoutube do
  @moduledoc """
  A captions fetcher for YouTube.
  Based upon https://github.com/Valian/youtube-captions, but adapted with Httpoison.
  """

  @behaviour CF.Videos.CaptionsFetcher

  require Logger
  import SweetXml

  @impl true
  def fetch(%{youtube_id: youtube_id, language: language}) do
    with {:ok, data} <- fetch_youtube_data(youtube_id),
         {:ok, caption_tracks} <- parse_caption_tracks(data),
         {:ok, transcript_url} <- find_transcript_url(caption_tracks, language),
         {:ok, transcript_data} <- fetch_transcript(transcript_url) do
      {:ok,
       %{
         raw: transcript_data,
         parsed: process_transcript(transcript_data),
         format: "xml"
       }}
    end
  end

  defp fetch_youtube_data(video_id) do
    url = "https://www.youtube.com/watch?v=#{video_id}"

    case HTTPoison.get(url, []) do
      {:ok, %HTTPoison.Response{body: body}} ->
        {:ok, body}

      {:error, %HTTPoison.Error{reason: reason}} ->
        {:error, "Failed to fetch YouTube video #{url}: #{inspect(reason)}"}
    end
  end

  defp parse_caption_tracks(data) do
    captions_regex = ~r/"captionTracks":(?<data>\[.*?\])/

    case Regex.named_captures(captions_regex, data) do
      %{"data" => data} -> {:ok, Jason.decode!(data)}
      _ -> {:error, :not_found}
    end
  end

  defp find_transcript_url(caption_tracks, lang) do
    case Enum.find(caption_tracks, &Regex.match?(~r".#{lang}", &1["vssId"])) do
      nil ->
        {:error, :language_not_found}

      %{"baseUrl" => base_url} ->
        {:ok, base_url}

      _data ->
        {:error, :language_url_not_found}
    end
  end

  defp fetch_transcript(base_url) do
    case HTTPoison.get(base_url, []) do
      {:ok, %HTTPoison.Response{body: body}} ->
        {:ok, body}

      {:error, %HTTPoison.Error{reason: reason}} ->
        {:error, "Failed to fetch transcript: #{inspect(reason)}"}
    end
  end

  defp process_transcript(transcript) do
    transcript
    |> SweetXml.xpath(
      ~x"//transcript/text"l,
      text: ~x"./text()"s |> transform_by(&clean_text/1),
      start: ~x"./@start"s |> transform_by(&parse_float/1),
      duration: ~x"./@dur"os |> transform_by(&parse_float/1)
    )
    |> Enum.filter(fn %{text: text, start: start} ->
      start != nil and text != nil and text != ""
    end)
  end

  defp clean_text(text) do
    text
    |> String.replace("&amp;", "&")
    |> HtmlEntities.decode()
    |> String.trim()
  end

  defp parse_float(val) do
    case Float.parse(val) do
      {num, _} -> num
      _ -> nil
    end
  end

  # Below is an implementation using the official YouTube API, but it requires OAuth2 authentication.
  # It is left here for reference, in case we loose access to the unofficial API.
  def fetch_captions_content_with_official_api(video_id, locale) do
    {:ok, token} = Goth.fetch(CF.Goth)
    conn = GoogleApi.YouTube.V3.Connection.new(token.token)

    IO.inspect(token)

    {:ok, result} = GoogleApi.YouTube.V3.Api.Captions.youtube_captions_list(conn, ["snippet"], video_id, [])
    IO.inspect(Enum.count(result.items))
    caption_id = List.first(result.items).id
    {:ok, caption} =
      GoogleApi.YouTube.V3.Api.Captions.youtube_captions_download(conn, caption_id, []) #FAILS, you can only download captions for your own videos :-(
  end
end

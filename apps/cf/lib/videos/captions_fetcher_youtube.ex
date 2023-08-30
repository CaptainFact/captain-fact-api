defmodule CF.Videos.CaptionsFetcherYoutube do
  @moduledoc """
  A captions fetcher for YouTube.
  Based upon https://github.com/Valian/youtube-captions, but adapted with Httpoison.
  """

  @behaviour CF.Videos.CaptionsFetcher

  require Logger

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
    |> String.replace(~r/^<\?xml version="1.0" encoding="utf-8"\?><transcript>/, "")
    |> String.replace("</transcript>", "")
    |> String.split("</text>")
    |> Enum.filter(&(String.trim(&1) != ""))
    |> Enum.map(&process_line/1)
  end

  defp process_line(line) do
    %{"start" => start} = Regex.named_captures(~r/start="(?<start>[\d.]+)"/, line)
    %{"dur" => dur} = Regex.named_captures(~r/dur="(?<dur>[\d.]+)"/, line)

    text =
      line
      |> String.replace("&amp;", "&")
      |> String.replace(~r/<text.+>/, "")
      |> String.replace(~r"</?[^>]+(>|$)", "")
      |> HtmlEntities.decode()
      |> String.trim()

    %{start: parse_float(start), duration: parse_float(dur), text: text}
  end

  defp parse_float(val) do
    {num, _} = Float.parse(val)
    num
  end

  # Below is an implementation using the official YouTube API, but it requires OAuth2 authentication.
  # It is left here for reference, in case we loose access to the unofficial API.
  # defp fetch_captions_content_with_official_api(video_id, locale) do
  #   # TODO: Continue dev here. See https://www.perplexity.ai/search/Can-you-show-jioyCtw.S4yrL8mlIBdqGg
  #   {:ok, token} = Goth.Token.for_scope("https://www.googleapis.com/auth/youtube.force-ssl")
  #   conn = YouTubeConnection.new(token.token)
  # {:ok, captions} = GoogleApi.YouTube.V3.Api.Captions.youtube_captions_list(conn, ["snippet"], video_id, [])
  # {
  #   "kind": "youtube#captionListResponse",
  #   "etag": "kMTAKpyU_VGu7GxgEnxXHqcuEXM",
  #   "items": [
  #     {
  #       "kind": "youtube#caption",
  #       "etag": "tWo68CIcRRFZA0oXPt8HGxCYia4",
  #       "id": "AUieDaZJxYug0L5YNAw_31GbXz73b0CPXCDFlsPNSNe7KQvuv1g",
  #       "snippet": {
  #         "videoId": "v2IoEhuho2k",
  #         "lastUpdated": "2024-06-16T18:45:12.56697Z",
  #         "trackKind": "asr",
  #         "language": "fr",
  #         "name": "",
  #         "audioTrackType": "unknown",
  #         "isCC": false,
  #         "isLarge": false,
  #         "isEasyReader": false,
  #         "isDraft": false,
  #         "isAutoSynced": false,
  #         "status": "serving"
  #       }
  #     }
  #   ]
  # }
  # caption_id = List.first(captions.items).id # TODO inspect to pick the right caption
  # {:ok, caption} = GoogleApi.YouTube.V3.Api.Captions.youtube_captions_download(conn, caption_id, [])
  # end
end

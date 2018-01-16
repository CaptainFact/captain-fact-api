defmodule CaptainFactGraphql.Resolvers.Videos do
  import Absinthe.Resolution.Helpers, only: [batch: 3]

  alias CaptainFact.Videos


  # Queries

  def get(_root, %{id: id}, _info) do
    case Videos.get_video_by_id(id) do
      nil -> {:error, "Video #{id} doesn't exist"}
      video -> {:ok, video}
    end
  end

  def get(_root, %{url: url}, _info) do
    case Videos.get_video_by_url(url) do
      nil -> {:error, "Video with url #{url} doesn't exist"}
      video -> {:ok, video}
    end
  end

  def list(_root, args, _info) do
    {:ok, Videos.videos_list(args[:filters] || [], false)}
  end

  # Fields

  def url(video, _, _) do
    {:ok, Videos.Video.build_url(video)}
  end

  def speakers(video, _, _) do
    batch({__MODULE__, :videos_speakers}, video.id, fn results ->
      {:ok, Map.get(results, video.id)}
    end)
  end

  def videos_speakers(_, videos_ids) do
    Videos.videos_speakers(videos_ids)
  end
end
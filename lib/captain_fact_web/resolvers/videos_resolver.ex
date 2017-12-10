defmodule CaptainFactWeb.Resolvers.VideosResolver do
  import Ecto.Query

  alias CaptainFact.Repo
  alias CaptainFact.Videos


  def url(video, _, _) do
    {:ok, Videos.Video.build_url(video)}
  end

  def hash_id(video, _, _) do
    {:ok, Videos.VideoHashId.encode(video.id)}
  end

  def statements(video, %{include_banned: true}, _) do
    {:ok, Repo.preload(video, :statements).statements}
  end
  def statements(video, _, _) do
    {:ok, Repo.all(from s in CaptainFact.Speakers.Statement, where: s.video_id == ^video.id and s.is_removed == false)}
  end

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

  def list(_root, %{language: language}, _info),
    do: {:ok, Videos.videos_list(language: language)}
  def list(_root, _args, _info),
    do: {:ok, Videos.videos_list()}
end
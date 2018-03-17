defmodule CaptainFactGraphql.Resolvers.Videos do
  import Ecto.Query

  alias DB.Repo
  alias DB.Schema.Video


  # Queries

  def get(_root, %{id: id}, _info) do
    case get_video_by_id(id) do
      nil -> {:error, "Video #{id} doesn't exist"}
      video -> {:ok, video}
    end
  end

  def get(_root, %{hash_id: id}, _info) do
    case get_video_by_id(id) do
      nil -> {:error, "Video #{id} doesn't exist"}
      video -> {:ok, video}
    end
  end

  def get(_root, %{url: url}, _info) do
    case get_video_by_url(url) do
      nil -> {:error, "Video with url #{url} doesn't exist"}
      video -> {:ok, video}
    end
  end

  def list(_root, args, _info) do
    videos_list = Repo.all(Video.query_list(Video, args[:filters] || []))
    {:ok, videos_list}
  end

  # Fields

  def url(video, _, _) do
    {:ok, DB.Schema.Video.build_url(video)}
  end

  # !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
  # TODO [Refactor] All videos queries have been temporarily copied here
  # so we can cut the dependence to :captain_fact.
  # However, we need to extract core features from :captain_fact
  # and re-add the dependency to avoid duplicate code in the future

  defp get_video_by_url(url) do
    case Video.parse_url(url) do
      {provider, id} ->
        Repo.get_by(Video.with_speakers(Video), provider: provider, provider_id: id)
      nil ->
        nil
    end
  end

  defp get_video_by_id(id), do: Repo.get(Video, id)
end
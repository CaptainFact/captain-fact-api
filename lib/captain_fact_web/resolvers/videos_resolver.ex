defmodule CaptainFactWeb.Resolvers.VideosResolver do
  import Absinthe.Resolution.Helpers, only: [on_load: 2]

  alias CaptainFact.Repo
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
    {:ok, Videos.videos_list(args[:filters] || [])}
  end

  # Fields

  def url(video, _, _) do
    {:ok, Videos.Video.build_url(video)}
  end

  def speakers(video, _, _) do
    # As speakers use a many-to-many association with "through" and DataLoader doesn't really
    # [support it at the moment](https://github.com/absinthe-graphql/dataloader/issues/5), they're preloaded in Videos
    # to avoid over-complexity with the code.
    # Code below force loading them if not already but would result in n+1 request if listing videos without preloading
    # first
    {:ok, Repo.preload(video, :speakers).speakers}
  end
end
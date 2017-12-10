defmodule CaptainFactWeb.Schema do
  use Absinthe.Schema
  import_types CaptainFactWeb.Schema.ContentTypes

  alias CaptainFactWeb.Resolvers.VideosResolver


  query do
    @desc "Get all videos"
    field :all_videos, list_of(:video) do
      arg :language, :string
      resolve &VideosResolver.list/3
    end

    @desc "Get a single video"
    field :video, :video do
      arg :id, :video_hash_id
      arg :url, :string
      resolve &VideosResolver.get/3
    end
  end
end
defmodule CaptainFactWeb.Schema do
  use Absinthe.Schema
  import_types CaptainFactWeb.Schema.ContentTypes

  alias CaptainFactWeb.Resolvers.VideosResolver

  # Build context

  def context(ctx) do
    ctx
    |> Map.put(:loader, dataloader())
  end

  def dataloader() do
    alias CaptainFact.Videos
    Dataloader.new
    |> Dataloader.add_source(Videos, Videos.data())
  end

  def plugins() do
    [Absinthe.Middleware.Dataloader | Absinthe.Plugin.defaults]
  end


  # Actual API

  input_object :video_filter do
    field :language, :string
    field :min_id, :video_hash_id
    field :speaker_id, :id
    field :speaker_slug, :string
  end

  query do
    @desc "Get all videos"
    field :all_videos, list_of(:video) do
      arg :filters, :video_filter
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
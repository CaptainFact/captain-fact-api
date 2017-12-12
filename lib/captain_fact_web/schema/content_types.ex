defmodule CaptainFactWeb.Schema.ContentTypes do
  use Absinthe.Schema.Notation
  import Absinthe.Resolution.Helpers
  import Ecto.Query

  alias CaptainFact.Videos
  alias CaptainFact.Speakers.Statement
  alias CaptainFactWeb.Resolvers.{VideosResolver, StatementsResolver, SpeakersResolver}


  scalar :video_hash_id do
    parse fn input ->
      with %Absinthe.Blueprint.Input.String{value: value} <- input do
        CaptainFact.Videos.VideoHashId.decode(value)
      else
        _ -> :error
      end
    end

    serialize fn id ->
      CaptainFact.Videos.VideoHashId.encode(id)
    end
  end

  @desc "A video"
  object :video do
    @desc "Unique identifier"
    field :id, non_null(:video_hash_id)
    @desc "Video title extracted from provider"
    field :title, non_null(:string)
    @desc "Video URL"
    field :url, non_null(:string), do: resolve &VideosResolver.url/3
    @desc "Video provider (Youtube, Vimeo...etc)"
    field :provider, non_null(:string)
    @desc "Unique ID used to identify video with provider"
    field :provider_id, non_null(:string)
    @desc "Language of the video represented as a two letters locale"
    field :language, :string
    @desc "List all non-removed statements for this video"
    field :statements, list_of(:statement), do: resolve dataloader(Videos, :statements)
    @desc "List all non-removed speakers for this video"
    field :speakers, list_of(:speaker), do: resolve &VideosResolver.speakers/3
  end

  object :statement do
    field :id, non_null(:id)
    field :text, non_null(:string)
    field :time, non_null(:integer)
    field :is_removed, non_null(:boolean)

    field :video, non_null(:video), do: resolve dataloader(Videos, :video)
    field :speaker, :speaker, do: resolve dataloader(Videos, :speaker)
#    field :comments, list_of(:comment), resolve dataloader(Videos, :comments)
  end

  object :speaker do
    field :id, non_null(:id)
    field :full_name, non_null(:string)
    field :title, :string
    field :slug, :string
    field :country, :string
    field :wikidata_item_id, :integer
    field :is_user_defined, non_null(:boolean)
    field :is_removed, non_null(:boolean)

    field :picture, :string, do: resolve &SpeakersResolver.picture/3
    field :videos, list_of(:video), do: resolve &SpeakersResolver.videos/3
  end
end
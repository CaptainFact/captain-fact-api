defmodule CaptainFactWeb.Schema.ContentTypes do
  use Absinthe.Schema.Notation

  alias CaptainFactWeb.Resolvers.{VideosResolver, StatementsResolver}


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
    @desc "List all statements for this video"
    field :statements, list_of(:statement) do
      arg :include_banned, :boolean
      resolve &VideosResolver.statements/3
    end
  end

  object :statement do
    field :id, non_null(:id)
    field :text, non_null(:string)
    field :time, non_null(:integer)
    field :is_removed, non_null(:boolean)

    field :video, non_null(:video), do: resolve &StatementsResolver.video/3
#    belongs_to :speaker, CaptainFact.Speakers.Speaker
#
#    has_many :comments, CaptainFact.Comments.Comment, on_delete: :delete_all
  end
end
defmodule CaptainFactWeb.Schema.ContentTypes do
  use Absinthe.Schema.Notation
  use Absinthe.Ecto, repo: CaptainFact.Repo

  alias CaptainFactWeb.Resolvers



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
    @desc "Unique identifier as a hash (min length: 4)"
    field :id, non_null(:video_hash_id)
    @desc "Video title as extracted from provider"
    field :title, non_null(:string)
    @desc "Video URL"
    field :url, non_null(:string), do: resolve &Resolvers.Videos.url/3
    @desc "Video provider (Youtube, Vimeo...etc)"
    field :provider, non_null(:string)
    @desc "Unique ID used to identify video with provider"
    field :provider_id, non_null(:string)
    @desc "Language of the video represented as a two letters locale"
    field :language, :string
    @desc "List all non-removed statements for this video"
    field :statements, list_of(:statement), do: resolve assoc(:statements)
    @desc "List all non-removed speakers for this video"
    field :speakers, list_of(:speaker), do: resolve &Resolvers.Videos.speakers/3
  end

  object :statement do
    field :id, non_null(:id)
    field :text, non_null(:string)
    field :time, non_null(:integer)
    field :is_removed, non_null(:boolean)

    field :video, non_null(:video), do: resolve assoc(:video)
    field :speaker, :speaker, do: resolve assoc(:speaker)
    field :comments, list_of(:comment), do: resolve assoc(:comments)
  end

  object :comment do
    field :id, non_null(:id)
    field :statement, non_null(:statement)
    field :user, non_null(:user), do: resolve assoc(:user)
    field :reply_to_id, :id
    field :reply_to, :comment, do: resolve assoc(:reply_to)
    field :text, :string
    field :approve, :boolean
    field :source, :string
    field :score, non_null(:integer), do: resolve &Resolvers.Comments.score/3
    field :inserted_at, :string
  end

  object :user do
    field :id, non_null(:id)
    field :username, non_null(:string)
    field :name, :string
    field :reputation, :integer
    field :picture_url, :string, do: &Resolvers.Users.picture/3
    field :mini_picture_url, :string, do: &Resolvers.Users.mini_picture/3
    field :achievements, list_of(:integer)
    field :registered_at, :string, do: resolve fn u, _, _ -> {:ok, u.inserted_at} end
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

    field :picture, :string, do: resolve &Resolvers.Speakers.picture/3
    field :videos, list_of(:video), do: resolve &Resolvers.Speakers.videos/3
  end
end
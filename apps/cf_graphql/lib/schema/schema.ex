defmodule CF.Graphql.Schema do
  use Absinthe.Schema
  alias CF.Graphql.Resolvers
  alias CF.Graphql.Schema.Middleware

  import_types(CF.Graphql.Schema.Types)

  # Actual API

  input_object :video_filter do
    field(:language, :string)
    field(:min_id, :id)
    field(:speaker_id, :id)
    field(:speaker_slug, :string)
    field(:is_partner, :boolean)
  end

  query do
    @desc "[Deprecated] Get all videos"
    @deprecated "Please update to the paginated version (videos). This will be removed in 0.9."
    @since "0.8.16"
    field :all_videos, list_of(:video) do
      arg(:filters, :video_filter)
      arg(:limit, :integer)
      resolve(&Resolvers.Videos.list/3)
    end

    @desc "Get all videos"
    field :videos, :paginated_videos do
      arg(:filters, :video_filter)
      arg(:offset, :integer, default_value: 1)
      arg(:limit, :integer, default_value: 10)
      resolve(&Resolvers.Videos.paginated_list/3)
    end

    @desc "Get a single video"
    field :video, :video do
      arg(:id, :id)
      arg(:hash_id, :id)
      arg(:url, :string)
      resolve(&Resolvers.Videos.get/3)
    end

    @desc "Get user public info"
    field :user, :user do
      arg(:id, :id)
      arg(:username, :string)
      resolve(&Resolvers.Users.get/3)
    end

    @desc "Get logged in user"
    field :loggedin_user, :user do
      middleware(Middleware.RequireAuthentication)
      resolve(&Resolvers.Users.get_logged_in/3)
    end

    @desc "Get app info"
    field :app_info, :app_info do
      resolve(&Resolvers.AppInfo.info/3)
    end

    @desc "Get all_statistics"
    field :all_statistics, :statistics do
      resolve(&Resolvers.Statistics.default/3)
    end
  end
end

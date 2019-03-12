defmodule CF.Graphql.Schema do
  use Absinthe.Schema
  alias CF.Graphql.Resolvers
  alias CF.Graphql.Schema.Middleware

  import_types(CF.Graphql.Schema.Types)
  import_types(CF.Graphql.Schema.InputObjects)

  # Query API

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
    field :logged_in_user, :user do
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

  # Mutation API

  mutation do
    @desc "Use this to mark a notifications as seen"
    field :update_notifications, list_of(:notification) do
      arg(:ids, non_null(list_of(:id)))
      arg(:seen, non_null(:boolean))

      resolve(&Resolvers.Notifications.update/3)
    end
  end
end

defmodule CF.Graphql.Schema.Types.User do
  @moduledoc """
  Representation of a `DB.Schema.User` for Absinthe
  """

  use Absinthe.Schema.Notation

  import CF.Graphql.Schema.Utils
  alias CF.Graphql.Schema.Middleware
  alias CF.Graphql.Resolvers

  @desc "The notifications status"
  enum :notifications_filter do
    value(:all, description: "All notifications")
    value(:seen, description: "Seen notifications")
    value(:unseen, description: "Unseen notifications")
  end

  @desc "Whether the user was a target or an author of the action"
  enum :activity_log_direction do
    value(:all, description: "All actions")
    value(:author, description: "Actions taken by the author")
    value(:target, description: "Actions taken against the target")
  end

  @desc "A user registered on the website"
  object :user do
    @desc "Unique user ID"
    field(:id, non_null(:id))

    @desc "Unique username"
    field(:username, non_null(:string))

    @desc "Optional full-name"
    field(:name, :string)

    @desc "Reputation of the user. See https://captainfact.io/help/reputation"
    field(:reputation, :integer)

    @desc "User's reputation of the day. See https://captainfact.io/help/reputation"
    field(:today_reputation_gain, :integer)

    @desc "User picture url (96x96)"
    field(:picture_url, non_null(:string), do: resolve(&Resolvers.Users.picture_url/3))

    @desc "Small version of the user picture (48x48)"
    field(:mini_picture_url, non_null(:string), do: resolve(&Resolvers.Users.mini_picture_url/3))

    @desc "A list of user's achievements as a list of integers"
    field(:achievements, list_of(:integer))

    @desc "User's registration datetime"
    field(:registered_at, :string, do: fn u, _, _ -> {:ok, u.inserted_at} end)

    @desc "User activity log"
    field :actions, :activity_log do
      complexity(join_complexity())
      arg(:offset, :integer, default_value: 1)
      arg(:limit, :integer, default_value: 10)
      arg(:direction, :activity_log_direction, default_value: :author)
      resolve(&Resolvers.Users.activity_log/3)
    end

    @desc "User notifications"
    field :notifications, :paginated_notifications do
      middleware(Middleware.RequireAuthentication)
      complexity(join_complexity())
      arg(:page, :integer, default_value: 1)
      arg(:page_size, :integer, default_value: 10)
      arg(:filter, :notifications_filter, default_value: :all)
      resolve(&Resolvers.Notifications.for_user/3)
    end

    @desc "Actions pending moderation"
    field :actions_pending_moderation, :integer do
      middleware(Middleware.RequireAuthentication)
      resolve(&Resolvers.Users.pending_moderations/3)
    end

    @desc "User subscriptions"
    field :subscriptions, list_of(:notifications_subscription) do
      middleware(Middleware.RequireAuthentication)
      complexity(join_complexity())
      arg(:scopes, list_of(:string), default_value: ["video", "statement"])
      arg(:is_subscribed, :boolean, default_value: true)
      arg(:video_id, :integer)
      resolve(&Resolvers.Notifications.subscriptions/3)
    end

    @desc "A paginated list of videos added by this user"
    field :videos_added, :paginated_videos do
      complexity(join_complexity())
      arg(:offset, :integer, default_value: 1)
      arg(:limit, :integer, default_value: 10)
      resolve(&Resolvers.Users.videos_added/3)
    end
  end

  @desc "A paginated list of user actions"
  object :activity_log do
    import_fields(:paginated)
    field(:entries, list_of(:user_action))
  end
end

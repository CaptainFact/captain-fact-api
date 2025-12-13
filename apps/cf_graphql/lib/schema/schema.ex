defmodule CF.Graphql.Schema do
  use Absinthe.Schema
  alias CF.Graphql.{Resolvers, Subscriptions}
  alias CF.Graphql.Schema.Middleware

  import_types(Absinthe.Plug.Types)

  import_types(CF.Graphql.Schema.Types.{
    AppInfo,
    Comment,
    JSON,
    Notification,
    Paginated,
    Source,
    Speaker,
    Statement,
    Statistics,
    Subscription,
    SubscriptionEvents,
    UserAction,
    User,
    Video,
    VideoCaption
  })

  import_types(CF.Graphql.Schema.InputObjects.{
    VideoFilter,
    StatementFilter
  })

  def context(ctx) do
    loader =
      Dataloader.new()
      |> Dataloader.add_source(DB.Repo, Dataloader.Ecto.new(DB.Repo))

    Map.put(ctx, :loader, loader)
  end

  def plugins do
    [Absinthe.Middleware.Dataloader | Absinthe.Plugin.defaults()]
  end

  # Query API

  query do
    @desc "[Deprecated] Get all videos"
    @deprecated "Please update to the paginated version (videos). This will be removed in 0.9."
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

    @desc "Get all statements"
    field :statements, :paginated_statements do
      arg(:filters, :statement_filter)
      arg(:offset, :integer, default_value: 1)
      arg(:limit, :integer, default_value: 10)
      resolve(&Resolvers.Statements.paginated_list/3)
    end

    @desc "Get user public info"
    field :user, :user do
      arg(:id, :id)
      arg(:username, :string)
      resolve(&Resolvers.Users.get/3)
    end

    @desc "Get logged in user"
    field :logged_in_user, :user do
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

    @desc "Search for speakers by name"
    field :search_speakers, list_of(:speaker) do
      arg(:query, non_null(:string))
      arg(:limit, :integer, default_value: 5)

      resolve(&Resolvers.Speakers.search_speakers/3)
    end

    @desc "Get a single speaker"
    field :speaker, :speaker do
      arg(:id, :id)
      arg(:slug, :string)
      resolve(&Resolvers.Speakers.get/3)
    end

    @desc "Get history actions for a video"
    field :video_history_actions, list_of(:user_action) do
      arg(:video_id, non_null(:id))
      resolve(&Resolvers.History.video_history_actions/3)
    end

    @desc "Get history actions for a statement"
    field :statement_history_actions, list_of(:user_action) do
      arg(:statement_id, non_null(:id))
      resolve(&Resolvers.History.statement_history_actions/3)
    end
  end

  # Mutation API

  mutation do
    @desc "Use this to mark a notifications as seen"
    field :update_notifications, list_of(:notification) do
      middleware(Middleware.RequireAuthentication)

      arg(:ids, non_null(list_of(:id)))
      arg(:seen, non_null(:boolean))

      resolve(&Resolvers.Notifications.update/3)
    end

    @desc "Use this to (un)subscribe from an item notifications"
    field :update_subscription, :notifications_subscription do
      middleware(Middleware.RequireAuthentication)

      arg(:scope, non_null(:string))
      arg(:entity_id, non_null(:id))
      arg(:is_subscribed, non_null(:boolean))
      arg(:reason, :string)

      resolve(&Resolvers.Notifications.update_subscription/3)
    end

    @desc "Use this to start the automatic statements extraction job. Requires elevated permissions."
    field :start_automatic_statements_extraction, :video do
      middleware(Middleware.RequireAuthentication)
      middleware(Middleware.RequireReputation, 450)

      arg(:video_id, non_null(:id))

      resolve(&Resolvers.Videos.start_automatic_statements_extraction/3)
    end

    field :edit_video, :video do
      middleware(Middleware.RequireAuthentication)
      # MIN_REPUTATION_UPDATE_VIDEO
      middleware(Middleware.RequireReputation, 75)

      arg(:id, non_null(:id))
      arg(:unlisted, non_null(:boolean))

      resolve(&Resolvers.Videos.edit/3)
    end

    @desc "Shift all statements of a video by a given offset"
    field :shift_statements, :video do
      middleware(Middleware.RequireAuthentication)
      middleware(Middleware.RequireReputation, 75)

      arg(:video_id, non_null(:id))
      arg(:youtube_offset, non_null(:integer))

      resolve(&Resolvers.Videos.shift_statements/3)
    end

    field :set_video_captions, :video do
      middleware(Middleware.RequireAuthentication)
      middleware(Middleware.RequireReputation, 450)

      arg(:video_id, non_null(:id))
      arg(:captions, non_null(:upload))

      resolve(&Resolvers.Videos.set_captions/3)
    end

    @desc "Create a new statement on a video"
    field :create_statement, :statement do
      middleware(Middleware.RequireAuthentication)

      arg(:video_id, non_null(:id))
      arg(:text, non_null(:string))
      arg(:time, non_null(:integer))
      arg(:speaker_id, :id)
      arg(:is_draft, :boolean)

      resolve(&Resolvers.Statements.create/3)
    end

    @desc "Update an existing statement"
    field :update_statement, :statement do
      middleware(Middleware.RequireAuthentication)

      arg(:id, non_null(:id))
      arg(:text, :string)
      arg(:time, :integer)
      arg(:speaker_id, :id)
      arg(:is_draft, :boolean)

      resolve(&Resolvers.Statements.update/3)
    end

    @desc "Delete an existing statement"
    field :delete_statement, :statement_removed do
      middleware(Middleware.RequireAuthentication)
      middleware(Middleware.RequireReputation, 75)

      arg(:id, non_null(:id))

      resolve(&Resolvers.Statements.delete/3)
    end

    @desc "Restore a deleted statement"
    field :restore_statement, :statement do
      middleware(Middleware.RequireAuthentication)

      arg(:id, non_null(:id))

      resolve(&Resolvers.Statements.restore/3)
    end

    @desc "Create a new comment on a statement"
    field :create_comment, :comment do
      middleware(Middleware.RequireAuthentication)

      arg(:statement_id, non_null(:id))
      arg(:text, :string)
      arg(:source, :string)
      arg(:reply_to_id, :id)
      arg(:approve, :boolean)

      resolve(&Resolvers.Comments.create/3)
    end

    @desc "Delete an existing comment"
    field :delete_comment, :comment_removed do
      middleware(Middleware.RequireAuthentication)

      arg(:id, non_null(:id))

      resolve(&Resolvers.Comments.delete/3)
    end

    @desc "Vote on a comment"
    field :vote_comment, :comment do
      middleware(Middleware.RequireAuthentication)

      arg(:comment_id, non_null(:id))
      arg(:value, non_null(:integer))

      resolve(&Resolvers.Comments.vote/3)
    end

    @desc "Flag a comment"
    field :flag_comment, :comment_flagged do
      middleware(Middleware.RequireAuthentication)

      arg(:comment_id, non_null(:id))
      arg(:reason, non_null(:integer))

      resolve(&Resolvers.Comments.flag/3)
    end

    @desc "Add an existing speaker to a video"
    field :add_speaker_to_video, :speaker do
      middleware(Middleware.RequireAuthentication)

      arg(:video_id, non_null(:id))
      arg(:speaker_id, non_null(:id))

      resolve(&Resolvers.Speakers.add_speaker_to_video/3)
    end

    @desc "Create a new speaker and add it to a video"
    field :create_speaker, :speaker do
      middleware(Middleware.RequireAuthentication)

      arg(:video_id, non_null(:id))
      arg(:full_name, non_null(:string))

      resolve(&Resolvers.Speakers.create_speaker/3)
    end

    @desc "Remove a speaker from a video"
    field :remove_speaker_from_video, :speaker_removed do
      middleware(Middleware.RequireAuthentication)

      arg(:video_id, non_null(:id))
      arg(:speaker_id, non_null(:id))

      resolve(&Resolvers.Speakers.remove_speaker_from_video/3)
    end

    @desc "Restore a removed speaker"
    field :restore_speaker, :speaker do
      middleware(Middleware.RequireAuthentication)

      arg(:speaker_id, non_null(:id))
      arg(:video_id, non_null(:id))

      resolve(&Resolvers.Speakers.restore_speaker/3)
    end

    @desc "Update an existing speaker"
    field :update_speaker, :speaker do
      middleware(Middleware.RequireAuthentication)

      arg(:id, non_null(:id))
      arg(:full_name, :string)
      arg(:title, :string)
      arg(:wikidata_item_id, :string)

      resolve(&Resolvers.Speakers.update_speaker/3)
    end
  end

  subscription do
    @desc "Listen for statements added on a video"
    field :statement_added, :statement do
      arg(:video_id, non_null(:id))
      config(&topic_by_video/2)
    end

    @desc "Listen for statements updated on a video"
    field :statement_updated, :statement do
      arg(:video_id, non_null(:id))
      config(&topic_by_video/2)
    end

    @desc "Listen for statements removed on a video"
    field :statement_removed, :statement_removed do
      arg(:video_id, non_null(:id))
      config(&topic_by_video/2)
    end

    @desc "Listen for comments added on a video"
    field :comment_added, :comment do
      arg(:video_id, non_null(:id))
      config(&topic_by_video/2)
    end

    @desc "Listen for comments updated on a video"
    field :comment_updated, :comment do
      arg(:video_id, non_null(:id))
      config(&topic_by_video/2)
    end

    @desc "Listen for comments removed on a video"
    field :comment_removed, :comment_removed do
      arg(:video_id, non_null(:id))
      config(&topic_by_video/2)
    end

    @desc "Listen for comment score changes on a video"
    field :comment_score_diff, :comment_score_diff do
      arg(:video_id, non_null(:id))
      config(&topic_by_video/2)
    end

    @desc "Listen for video updates"
    field :video_updated, :video do
      arg(:video_id, non_null(:id))
      config(&topic_by_video/2)
    end

    @desc "Listen for speakers added on a video"
    field :speaker_added, :speaker do
      arg(:video_id, non_null(:id))
      config(&topic_by_video/2)
    end

    @desc "Listen for speakers updated on a video"
    field :speaker_updated, :speaker do
      arg(:video_id, non_null(:id))
      config(&topic_by_video/2)
    end

    @desc "Listen for speakers removed on a video"
    field :speaker_removed, :speaker_removed do
      arg(:video_id, non_null(:id))
      config(&topic_by_video/2)
    end

    @desc "Listen for actions added to a video history"
    field :video_history_action_added, :user_action do
      arg(:video_id, non_null(:id))
      config(&topic_by_video_history/2)
    end

    @desc "Listen for actions added to a statement history"
    field :statement_history_action_added, :user_action do
      arg(:statement_id, non_null(:id))
      config(&topic_by_statement_history/2)
    end
  end

  defp topic_by_video(%{video_id: video_id}, _resolution) do
    {:ok, topic: Subscriptions.video_topic(video_id)}
  end

  defp topic_by_video_history(%{video_id: video_id}, _resolution) do
    {:ok, topic: Subscriptions.video_history_topic(video_id)}
  end

  defp topic_by_statement_history(%{statement_id: statement_id}, _resolution) do
    {:ok, topic: Subscriptions.statement_history_topic(statement_id)}
  end
end

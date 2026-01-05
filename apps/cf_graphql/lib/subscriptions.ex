defmodule CF.Graphql.Subscriptions do
  @moduledoc """
  Helpers to publish GraphQL subscription events alongside legacy Phoenix channels.
  """

  alias Absinthe.Subscription
  alias CF.GraphQLWeb.Endpoint

  @video_topic_prefix "video:"
  @video_history_topic_prefix "video_history:"
  @statement_history_topic_prefix "statement_history:"

  @spec video_topic(integer()) :: String.t()
  def video_topic(video_id), do: "#{@video_topic_prefix}#{video_id}"

  @spec video_history_topic(integer()) :: String.t()
  def video_history_topic(video_id), do: "#{@video_history_topic_prefix}#{video_id}"

  @spec statement_history_topic(integer()) :: String.t()
  def statement_history_topic(statement_id),
    do: "#{@statement_history_topic_prefix}#{statement_id}"

  def publish_statement_added(%{video_id: video_id} = statement) do
    publish(:statement_added, statement, video_topic(video_id))
  end

  def publish_statement_updated(%{video_id: video_id} = statement) do
    publish(:statement_updated, statement, video_topic(video_id))
  end

  def publish_statement_removed(statement_id, video_id) do
    payload = %{id: statement_id}
    publish(:statement_removed, payload, video_topic(video_id))
  end

  def publish_comment_added(comment, video_id) do
    publish(:comment_added, comment, video_topic(video_id))
  end

  def publish_comment_updated(comment, video_id) do
    publish(:comment_updated, comment, video_topic(video_id))
  end

  def publish_comment_removed(comment, video_id) do
    payload = %{
      id: comment.id,
      statement_id: comment.statement_id,
      reply_to_id: comment.reply_to_id
    }

    publish(:comment_removed, payload, video_topic(video_id))
  end

  def publish_comment_score_diff(comment, diff, video_id) do
    payload = %{
      comment: %{
        id: comment.id,
        statement_id: comment.statement_id,
        reply_to_id: comment.reply_to_id
      },
      diff: diff
    }

    publish(:comment_score_diff, payload, video_topic(video_id))
  end

  def publish_video_updated(video) do
    publish(:video_updated, video, video_topic(video.id))
  end

  def publish_speaker_added(speaker, video_id) do
    publish(:speaker_added, speaker, video_topic(video_id))
  end

  def publish_speaker_updated(speaker, video_id) do
    publish(:speaker_updated, speaker, video_topic(video_id))
  end

  def publish_speaker_removed(speaker_id, video_id) do
    publish(:speaker_removed, %{id: speaker_id}, video_topic(video_id))
  end

  def publish_video_history_action(action, video_id) do
    publish(:video_history_action_added, action, video_history_topic(video_id))
  end

  def publish_statement_history_action(action, statement_id) do
    publish(:statement_history_action_added, action, statement_history_topic(statement_id))
  end

  defp publish(event, payload, topic) do
    Subscription.publish(Endpoint, payload, [{event, topic}])
  end
end









defmodule DB.Schema.Subscription do
  @moduledoc """
  Represent a user's subscription to certain actions types. It allows users to
  subscribe (and thus get notifications) for events happening on videos,
  statements or comments he's watching.
  """

  use Ecto.Schema
  import Ecto.Changeset

  alias DB.Schema.Video
  alias DB.Schema.Statement
  alias DB.Schema.Comment

  schema "subscriptions" do
    belongs_to(:user, DB.Schema.User)
    belongs_to(:video, DB.Schema.Video)
    belongs_to(:statement, DB.Schema.Statement)
    belongs_to(:comment, DB.Schema.Comment)
    field(:scope, DB.Type.Entity, null: false)
    field(:reason, DB.Type.SubscriptionReason)
    field(:is_subscribed, :boolean, default: true, null: false)
  end

  @fields [:user_id, :video_id, :statement_id, :comment_id, :scope, :is_subscribed, :reason]
  @required_fields [:user_id, :scope]

  @doc """
  Builds a changeset based on the `struct` and `params`.
  """
  def changeset(struct, params \\ %{}) do
    struct
    |> cast(params, @fields)
    |> validate_required_by_scope()
    |> unique_constraint(:id, name: :subscriptions_user_id_video_id_statement_id_comment_id_index)
  end

  @doc """
  Build a subscription for given comment, statement or video entity.
  """
  def changeset_entity(struct, comment, reason \\ nil)

  def changeset_entity(struct, comment = %Comment{}, reason) do
    changeset(struct, %{
      video_id: comment.statement.video_id,
      statement_id: comment.statement_id,
      comment_id: comment.id,
      scope: :comment,
      reason: reason
    })
  end

  def changeset_entity(struct, statement = %Statement{}, reason) do
    changeset(struct, %{
      video_id: statement.video_id,
      statement_id: statement.id,
      scope: :statement,
      reason: reason
    })
  end

  def changeset_entity(struct, video = %Video{}, reason) do
    changeset(struct, %{
      video_id: video.id,
      scope: :video,
      reason: reason
    })
  end

  defp validate_required_by_scope(changeset) do
    case get_field(changeset, :scope) do
      nil ->
        validate_required(changeset, @required_fields)

      :video ->
        validate_required(changeset, @required_fields ++ [:video_id])

      :statement ->
        validate_required(changeset, @required_fields ++ [:video_id, :statement_id])

      :comment ->
        validate_required(changeset, @required_fields ++ [:video_id, :statement_id, :comment_id])

      scope ->
        add_error(changeset, :scope, "Invalid scope #{scope}")
    end
  end
end

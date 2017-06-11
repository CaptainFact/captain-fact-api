defmodule CaptainFact.Flag do
  use CaptainFact.Web, :model

  alias CaptainFact.{Comment, User}

  @comment_type 1

  schema "flags" do
    field :type, :integer
    field :entity_id, :integer
    belongs_to :source_user, CaptainFact.User
    belongs_to :target_user, CaptainFact.User

    timestamps()
  end

  @doc """
  Builds a changeset based on a `comment`
  """
  def changeset_comment(struct, comment = %Comment{}) do
    cast(struct, %{entity_id: comment.id, type: @comment_type}, [:entity_id, :type])
    |> put_assoc(:target_user, comment.user)
  end

  def comment_type(), do: @comment_type
end

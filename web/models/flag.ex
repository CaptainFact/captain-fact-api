defmodule CaptainFact.Flag do
  use CaptainFact.Web, :model

  alias CaptainFact.{Comment, User}

  @comment_type 1

  @reason_spam 1
  @reason_bad_language 2
  @reason_harassment 3

  schema "flags" do
    field :type, :integer
    field :reason, :integer
    field :entity_id, :integer
    belongs_to :source_user, CaptainFact.User
    belongs_to :target_user, CaptainFact.User

    timestamps()
  end

  @required_fields ~w(type reason entity_id source_user_id target_user_id)a

  @doc """
  Builds a changeset based on a `comment`
  """
  def changeset_comment(struct, comment = %Comment{}, otherParams = %{}) do
    params = Map.merge(%{
      entity_id: comment.id,
      type: @comment_type,
      target_user_id: comment.user_id
    }, otherParams)
    cast(struct, params, [:entity_id, :type, :reason, :target_user_id])
    |> validate_required(@required_fields)
  end

  def comment_type(), do: @comment_type
end

defmodule CF.Graphql.Schema.Types.Notification do
  @moduledoc """
  Represent a user's Notification.
  """

  use Absinthe.Schema.Notation
  use Absinthe.Ecto, repo: DB.Repo
  import CF.Graphql.Schema.Utils

  import_types(CF.Graphql.Schema.Types.Paginated)

  @desc "A user notification"
  object :notification do
    field(:id, non_null(:id))
    @desc "Type of the notification"
    field(:type, non_null(:string))
    @desc "Notification creation datetime"
    field(:inserted_at, non_null(:string))
    @desc "When the notification has been seen, or null if it has not"
    field(:seen_at, :string)
    @desc "Action the notification is referencing"
    field :action, :user_action do
      resolve(assoc(:action))
      complexity(join_complexity())
    end
  end

  @desc "A paginated list of user actions"
  object :paginated_notifications do
    import_fields(:paginated)
    field(:entries, list_of(:notification))
  end
end

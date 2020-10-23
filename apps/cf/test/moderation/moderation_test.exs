defmodule CF.ModerationTest do
  use CF.DataCase

  import CF.TestUtils, only: [flag_comments: 2]

  alias CF.Moderation
  alias DB.Schema.UserAction

  doctest CF.Moderation

  # TODO can only give one feedback
  # TODO cannot give feedback on an action which is not reported
  # TODO Make sure user doesn't get and cannot give feedback on its own actions or actions he's targeted by

  describe "unread_count" do
    test "no moderation entries if all open actions belong to users" do
      user = insert(:user, reputation: 1000)
      limit = max(Moderation.nb_flags_to_report(:create, :comment), 0)

      Enum.each(1..5, fn x ->
        comment =
          insert(:comment, %{user: user, text: "Own comment" <> to_string(x)})
          |> with_action()

        flag_comments([comment], limit)
      end)

      count = Moderation.unread_count!(user)
      assert count == 0
    end

    test "count pending actions from other users" do
      user = insert(:user, reputation: 1000)
      limit = Moderation.nb_flags_to_report(:create, :comment)

      comment =
        insert(:comment, %{user: user, text: "Own comment"})
        |> with_action()

      flag_comments([comment], limit)

      Enum.each(1..8, fn x ->
        comment = insert(:comment, %{text: "User comment " <> to_string(x)}) |> with_action()
        flag_comments([comment], limit)
        Repo
      end)

      count = Moderation.unread_count!(user)
      assert count == 8
    end

    test "count pending actions from other users, unless already moderated" do
      user = insert(:user, reputation: 1000)
      limit = Moderation.nb_flags_to_report(:create, :comment)
      comment = insert(:comment, %{user: user, text: "Own comment"}) |> with_action()
      flag_comments([comment], limit)

      Enum.each(1..8, fn x ->
        comment = insert(:comment, %{text: "User comment" <> to_string(x)}) |> with_action()
        flag_comments([comment], limit)

        # Produce feedback for two of the actions.
        if rem(x, 3) == 0 do
          action =
            Repo.get_by!(
              UserAction,
              entity: :comment,
              type: :create,
              comment_id: comment.id
            )

          Moderation.feedback!(user, action.id, 1, 1)
        end
      end)

      count = Moderation.unread_count!(user)
      assert count == 6
    end
  end
end

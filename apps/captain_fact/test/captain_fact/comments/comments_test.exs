defmodule CaptainFact.Comments.CommentsTest do
  use CaptainFact.DataCase

  import CaptainFact.TestUtils

  import CaptainFact.Support.MetaPage
  import DB.Schema.UserAction, only: [video_debate_context: 1]
  alias DB.Schema.UserAction
  alias DB.Schema.Comment
  alias DB.Schema.Source

  alias CaptainFact.Comments
  alias CaptainFact.TokenGenerator
  alias CaptainFact.Sources.Fetcher


  @valid_source_attributes %{
    language: "FR",
    title: "The article of the year",
    site_name: "Best site ever !",
    url: "/test"
  }

  describe "add_comment" do
    test "returns comment and call callback once updated" do
      # Start a server to provide a valid page
      attributes = Map.put(@valid_source_attributes, :url, unique_url())
      url = endpoint_url(serve(attributes.url, 200, attributes), attributes.url)

      # Add comment
      user = insert(:user)
      statement = insert(:statement)
      context = video_debate_context(statement.video_id)
      comment = Comments.add_comment(user, context, %{statement_id: statement.id}, url, fn updated_comment ->
        assert updated_comment.source.url == url
        assert updated_comment.source.title == attributes.title
        assert updated_comment.source.site_name == attributes.site_name
        assert updated_comment.source.language == attributes.language
      end)
      wait_fetcher()

      assert comment.source.title == nil
      assert comment.statement_id == statement.id
      assert comment.source.url == url
    end

    test "doesn't call callback if no updates required" do
      # Start a server to provide a valid page
      sub_url = unique_url()
      url =
        serve(sub_url, 200, %{})
        |> endpoint_url(sub_url)

      # Add comment
      user = insert(:user)
      statement = insert(:statement)
      Comments.add_comment(user, video_debate_context(statement.video_id), %{statement_id: statement.id}, url, fn _ ->
        raise "callback shouldn't be called if there's nothing to update"
      end)
      wait_fetcher()
    end

    test "source only fetched one time" do
      # Start a server to provide a valid page
      attributes = Map.put(@valid_source_attributes, :url, unique_url())
      url =
        serve(attributes.url, 200, attributes, only_once: true)
        |> endpoint_url(attributes.url)

      # Add comment
      user = insert(:user)
      statement = insert(:statement)
      comment_params = %{statement_id: statement.id}
      Comments.add_comment(user, video_debate_context(statement.video_id), comment_params, url, fn update_comment ->
        assert update_comment.source.title === attributes.title
      end)
      Comments.add_comment(user, video_debate_context(statement.video_id), comment_params, url, fn _ -> raise "source is re-fetched" end)
      wait_fetcher()
    end

    test "if og:url is different than given url, change comment's source" do
      base_url = unique_url()
      meta_url = unique_url()
      attributes = Map.put(@valid_source_attributes, :url, meta_url)
      url =
        serve(base_url, 200, attributes, only_once: true)
        |> endpoint_url(base_url)

      # Add comment
      user = insert(:user)
      statement = insert(:statement)
      comment_params = %{statement_id: statement.id}
      Comments.add_comment(user, video_debate_context(statement.video_id), comment_params, url, fn comment ->
        assert comment.source.title === attributes.title
        refute String.ends_with?(comment.source.url, base_url)
        assert String.ends_with?(comment.source.url, meta_url)
        # Ensure base source is deleted
        refute Repo.get_by(Source, url: base_url)
        refute Repo.get_by(Source, url: url)
      end)
      wait_fetcher()
    end

    test "if og:url is different from given url, change comment's url (re-use if existing)" do
      bypass = Bypass.open
      old_url = unique_url()
      real_source = insert(:source, %{url: endpoint_url(bypass, unique_url())})
      attributes = Map.put(@valid_source_attributes, :url, real_source.url)
      url =
        serve(bypass, old_url, 200, attributes, only_once: true)
        |> endpoint_url(old_url)

      # Add comment
      user = insert(:user)
      statement = insert(:statement)
      comment_params = %{statement_id: statement.id}
      Comments.add_comment(user, video_debate_context(statement.video_id), comment_params, url, fn comment ->
        assert comment.source.title == attributes.title
        assert comment.source.url == real_source.url
        assert comment.source.id == real_source.id
        # Ensure base source is deleted
        assert Repo.get_by(Source, url: url) == nil
      end)
      wait_fetcher()
    end

    #    test "if redirected, store redirect url"
  end

  describe "Delete comment" do
    test "only user can delete his own comment, and all history is wiped too" do
      comment = insert(:comment) |> with_action()
      random_user = insert(:user)

      assert_raise FunctionClauseError, fn -> Comments.delete_comment(random_user, comment) end
      refute_deleted(comment)

      Comments.delete_comment(comment.user, comment)
      assert_deleted(comment)
    end

    test "oh wait, actually admin can delete any comment" do
      comment = insert(:comment) |> with_action()
      Comments.admin_delete_comment(comment)
      assert_deleted(comment)
    end

    test "trying to delete the same comment multiple times returns nil" do
      comment = insert(:comment) |> with_action()
      assert Comments.admin_delete_comment(comment) != nil
      assert_deleted(comment)
      assert Comments.admin_delete_comment(comment) == nil
      assert Comments.delete_comment(comment.user, comment) == nil
    end

    test "a user cannot delete a reported comment waiting for moderation" do
      comment = insert_reported_comment()
      assert_raise FunctionClauseError, fn -> Comments.delete_comment(comment.user, comment) end
      refute_deleted comment
    end

    test "but an admin can" do
      comment = insert_reported_comment()
      assert Comments.admin_delete_comment(comment) != nil
      assert_deleted comment
    end

    test "deleting a comment deletes its replies and their actions" do
      comment = insert(:comment) |> with_action()
      replies = insert_comments_list_with_action(5, %{reply_to: comment})
      replies_replies = List.flatten(Enum.map(replies, fn c -> insert_comments_list_with_action(2, %{reply_to: c}) end))
      Comments.delete_comment(comment.user, comment)
      assert_deleted comment
      Enum.map(replies, &(assert_deleted(&1, false)))
      Enum.map(replies_replies, &(assert_deleted(&1, false)))
    end
  end

  defp insert_comments_list_with_action(size, params) do
    Enum.map(insert_list(size, :comment, params), &with_action/1)
  end

  defp insert_reported_comment() do
    limit = CaptainFact.Moderation.nb_flags_report(UserAction.type(:create), UserAction.entity(:comment))
    comment = insert(:comment) |> with_action() |> flag(limit)
    CaptainFactJobs.Flags.update()

    # Reload comment
    comment =
      Comment
      |> preload([:user])
      |> Repo.get(comment.id)

    assert comment.is_reported == true
    comment
  end

  defp unique_url(), do: "/#{TokenGenerator.generate(32)}"

  defp wait_fetcher() do
    case MapSet.size(Fetcher.get_queue()) do
      0 -> :ok
      _ ->
        :timer.sleep(50)
        wait_fetcher()
    end
  end
end
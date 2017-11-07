defmodule CaptainFact.Comments.CommentsTest do
  use CaptainFact.DataCase

  import CaptainFact.Support.MetaPage
  import CaptainFact.Actions.UserAction, only: [video_debate_context: 1]

  alias CaptainFact.Comments
  alias CaptainFact.TokenGenerator
  alias CaptainFact.Sources.{Source, Fetcher}


  @valid_source_attributes %{
    language: "fr", # TODO remplace by locale
    title: "The article of the year",
    site_name: "Best site ever !",
    url: "/test"
  }

  describe "add_comment" do
    test "returns comment and call callback once updated" do
      # Start a server to provide a valid page
      attributes = Map.put(@valid_source_attributes, :url, unique_url())
      url =
        serve(attributes.url, 200, attributes)
        |> endpoint_url(attributes.url)

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
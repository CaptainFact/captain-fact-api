defmodule CaptainFact.CommentsTest do
  use CaptainFact.DataCase

  import CaptainFact.Support.MetaPage
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
      attributes = Map.put(@valid_source_attributes, :url, url_without_validation())
      url =
        serve(attributes.url, 200, attributes)
        |> endpoint_url(attributes.url)

      # Add comment
      user = insert(:user)
      statement = insert(:statement)
      comment = Comments.add_comment(user, %{statement_id: statement.id}, url, fn updated_comment ->
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
      sub_url = url_without_validation()
      url =
        serve(sub_url, 200, %{})
        |> endpoint_url(sub_url)

      # Add comment
      user = insert(:user)
      statement = insert(:statement)
      Comments.add_comment(user, %{statement_id: statement.id}, url, fn _ ->
        raise "callback shouldn't be called if there's nothing to update"
      end)
      wait_fetcher()
    end

    test "source only fetched one time" do
      # Start a server to provide a valid page
      attributes = Map.put(@valid_source_attributes, :url, url_without_validation())
      url =
        serve(attributes.url, 200, attributes, only_once: true)
        |> endpoint_url(attributes.url)

      # Add comment
      user = insert(:user)
      statement = insert(:statement)
      comment_params = %{statement_id: statement.id}
      Comments.add_comment(user, comment_params, url, fn update_comment ->
        assert update_comment.source.title === attributes.title
      end)
      Comments.add_comment(user, comment_params, url, fn _ -> raise "source is re-fetched" end)
      wait_fetcher()
    end

    test "if og:url is different than given url, change comment's source" do
      base_url = url_without_validation()
      meta_url = url_without_validation()
      attributes = Map.put(@valid_source_attributes, :url, meta_url)
      url =
        serve(base_url, 200, attributes, only_once: true, ignore_meta_url_correction: true)
        |> endpoint_url(base_url)

      # Add comment
      user = insert(:user)
      statement = insert(:statement)
      comment_params = %{statement_id: statement.id}
      Comments.add_comment(user, comment_params, url, fn comment ->
        assert comment.source.title === attributes.title
        assert comment.source.url != base_url
        assert comment.source.url == meta_url
        # Ensure base source is deleted
        refute Repo.get_by(Source, url: base_url)
        refute Repo.get_by(Source, url: url)
      end)
      wait_fetcher()
    end

    test "if og:url is different from given url, change comment's url (re-use if existing)" do
      old_url = url_without_validation()
      real_source = insert(:source, %{url: url_without_validation()})
      attributes = Map.put(@valid_source_attributes, :url, real_source.url)
      url =
        serve(old_url, 200, attributes, only_once: true, ignore_meta_url_correction: true)
        |> endpoint_url(old_url)

      # Add comment
      user = insert(:user)
      statement = insert(:statement)
      comment_params = %{statement_id: statement.id}
      Comments.add_comment(user, comment_params, url, fn comment ->
        assert comment.source.title === attributes.title
        assert comment.source.url == real_source.url
        assert comment.source.id == real_source.id
        # Ensure base source is deleted
        assert Repo.get_by(Source, url: old_url) == nil
      end)
      wait_fetcher()
    end

#    test "if redirected, store redirect url"
  end

  defp url_without_validation(), do: "/__IGNORE_URL_VALIDATION__/#{TokenGenerator.generate(32)}"

  defp wait_fetcher() do
    case MapSet.size(Fetcher.get_queue()) do
      0 -> :ok
      _ ->
        :timer.sleep(50)
        wait_fetcher()
    end
  end
end
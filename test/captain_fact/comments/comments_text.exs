defmodule CaptainFact.CommentsTest do
  use CaptainFact.DataCase

  import CaptainFact.Support.MetaPage
  alias CaptainFact.Comments
  alias CaptainFact.TokenGenerator

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
    end
#    test "if the same source is added multiple times at the same moment, only fetch 1"
#    test "if og:url is different than given url, change comment's url'"
#    test "don't try to fetch anything if no source given"
  end

  defp url_without_validation(), do: "/__IGNORE_URL_VALIDATION__/#{TokenGenerator.generate(32)}"
end
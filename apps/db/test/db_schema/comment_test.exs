defmodule DB.Schema.CommentTest do
  use DB.DataCase, async: true

  alias DB.Schema.Comment

  @valid_attrs %{
    statement_id: 1,
    user_id: 42,
    text: Faker.Lorem.sentence(),
    source_title: Faker.Lorem.sentence()
  }

  @valid_source %{id: 42, url: Faker.Internet.url()}

  test "can post with a source and no text (fact)" do
    changeset =
      Comment.changeset(
        Map.merge(%Comment{}, %{source: @valid_source}),
        Map.delete(@valid_attrs, :text)
      )

    assert changeset.valid?
  end

  test "can post with a text and no source (comment)" do
    changeset = Comment.changeset(%Comment{}, Map.delete(@valid_attrs, :source))
    assert changeset.valid?
  end

  test "cannot post if there's no source and no text" do
    changeset = Comment.changeset(%Comment{}, Map.drop(@valid_attrs, [:source, :text]))
    refute changeset.valid?
  end

  test "cannot post without a statement" do
    changeset = Comment.changeset(%Comment{}, Map.delete(@valid_attrs, :statement_id))
    refute changeset.valid?
  end

  test "comment text length has a limit" do
    attrs = %{text: String.duplicate("x", Comment.max_length() + 1)}
    expected_error = {:text, "should be at most #{Comment.max_length()} character(s)"}
    assert expected_error in errors_on(%Comment{}, attrs)
  end

  test "comment text cannot contains urls" do
    attrs = %{text: "Hey check this out https://website.com/article it's awesome!"}
    expected_error = {:text, "Cannot include URL. Use source field instead"}
    assert expected_error in errors_on(%Comment{}, attrs)
  end
end

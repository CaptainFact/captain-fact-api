defmodule DB.Schema.CommentTest do
  use DB.DataCase, async: true

  alias DB.Schema.Comment

  @valid_attrs %{
    statement_id: 1,
    user_id: 42,
    text: Faker.Lorem.sentence,
    source_title: Faker.Lorem.sentence
  }

  @valid_source %{id: 42, url: Faker.Internet.url}

  test "can post with a source and no text (fact)" do
    changeset = Comment.changeset(Map.merge(%Comment{}, %{source: @valid_source}), Map.delete(@valid_attrs, :text))
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

  test "comment text length must be less than 255 characters" do
    attrs = %{text: String.duplicate("x", 256)}
    assert {:text, "should be at most 255 character(s)"} in
      errors_on(%Comment{}, attrs)
  end

  test "comment text cannot contains urls" do
    attrs = %{text: "Hey check this out https://website.com/article it's awesome!"}
    assert {:text, "Cannot include URL. Use source field instead"} in errors_on(%Comment{}, attrs)
  end
end

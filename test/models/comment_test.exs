defmodule CaptainFact.CommentTest do
  use CaptainFact.ModelCase, async: true

  alias CaptainFact.Comment

  @valid_attrs %{
    statement_id: 1,
    source: %{url: Faker.Internet.url},
    text: Faker.Lorem.sentence,
    source_title: Faker.Lorem.sentence
  }

  test "can post with a source and no text (fact)" do
    changeset = Comment.changeset(%Comment{}, Map.delete(@valid_attrs, :text))
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

  test "source url must be a valid URL" do
    attrs = put_in(@valid_attrs, [:source, :url], "INVALID URL")
    changeset = Comment.changeset(%Comment{}, attrs)
    refute changeset.valid?
  end

  test "comment text length must be less than 240 characters" do
    attrs = %{text: String.duplicate("x", 241)}
    assert {:text, "should be at most 240 character(s)"} in
      errors_on(%Comment{}, attrs)
  end
end

defmodule DB.Schema.SourceTest do
  use DB.DataCase, async: true

  alias DB.Schema.Source

  @valid_attrs %{
    title: "some content",
    file_mime_type: "application/pdf",
    url:
      "http://www.lemonde.fr/idees/article/2017/04/24/les-risques-d-une-explosion_5116380_3232.html"
  }
  @invalid_attrs %{}

  test "changeset with valid attributes" do
    changeset = Source.changeset(%Source{}, @valid_attrs)
    assert changeset.valid?
  end

  test "changeset with invalid attributes" do
    refute Source.changeset(%Source{}, @invalid_attrs).valid?
    refute Source.changeset(%Source{}, %{@valid_attrs | url: ""}).valid?
    refute Source.changeset(%Source{}, %{@valid_attrs | url: "http://"}).valid?
    refute Source.changeset(%Source{}, %{@valid_attrs | url: "https://x"}).valid?
    refute Source.changeset(%Source{}, %{@valid_attrs | url: "https://xxxxxx"}).valid?
    refute Source.changeset(%Source{}, %{@valid_attrs | url: "ftp://example.com/doc"}).valid?
    refute Source.changeset(%Source{}, %{@valid_attrs | url: "not-a-url"}).valid?
  end

  describe "url validation (URI.parse)" do
    test "accepts long public suffix / TLD (e.g. .institute)" do
      url =
        "https://manhattan.institute/article/new-study-finds-political-bias-embedded-in-wikipedia-articles"

      assert Source.changeset(%Source{}, %{@valid_attrs | url: url}).valid?
    end

    test "accepts multi-label hosts with common TLDs" do
      assert Source.changeset(%Source{}, %{
               @valid_attrs
               | url: "https://www.lemonde.fr/article/123"
             }).valid?

      assert Source.changeset(%Source{}, %{
               @valid_attrs
               | url: "https://en.wikipedia.org/wiki/Fact-checking"
             }).valid?
    end

    test "allows localhost and loopback addresses in test build" do
      # @allow_localhost is a compile-time constant (true when MIX_ENV == :test).
      assert Source.changeset(%Source{}, %{@valid_attrs | url: "http://localhost:4000/page"}).valid?
      assert Source.changeset(%Source{}, %{@valid_attrs | url: "http://localhost/path"}).valid?
      assert Source.changeset(%Source{}, %{@valid_attrs | url: "http://127.0.0.1:8080/"}).valid?
    end
  end

  test "changeset_fetched" do
    assert Source.changeset_fetched(%Source{}, @valid_attrs).valid?
    refute Source.changeset_fetched(%Source{}, %{@valid_attrs | file_mime_type: "zzzz"}).valid?
  end

  test "must add https:// if url doesn't start with http:// or https://" do
    changeset = Source.changeset(%Source{}, Map.put(@valid_attrs, :url, "amazing.com/article"))
    assert changeset.changes.url == "https://amazing.com/article"
  end

  test "should not accept URLs longer than 2048 characters" do
    attrs = %{@valid_attrs | url: url_generator(2049)}
    refute Source.changeset(%Source{}, attrs).valid?
    expected_error = {:url, "should be at most 2048 character(s)"}
    assert expected_error in errors_on(%Source{}, attrs)
  end

  @url_generator_base "https://captainfact.io/"
  defp url_generator(length) do
    @url_generator_base <>
      (fn -> "x" end
       |> Stream.repeatedly()
       |> Enum.take(length - String.length(@url_generator_base))
       |> Enum.join())
  end
end

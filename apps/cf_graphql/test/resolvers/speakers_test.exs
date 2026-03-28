defmodule CF.Graphql.Resolvers.SpeakersTest do
  use CF.Graphql.DataCase

  import DB.Factory

  alias CF.Graphql.Resolvers.Speakers

  setup do
    DB.Repo.delete_all(DB.Schema.Speaker)
    :ok
  end

  describe "search_speakers/3 — basic behaviour" do
    test "returns speakers whose name contains the query" do
      insert(:speaker, full_name: "John Smith")
      insert(:speaker, full_name: "Jane Doe")

      {:ok, results} = Speakers.search_speakers(nil, %{query: "John", limit: 10}, nil)

      assert length(results) == 1
      assert hd(results).full_name == "John Smith"
    end

    test "returns empty list when no speaker matches" do
      insert(:speaker, full_name: "John Smith")

      {:ok, results} = Speakers.search_speakers(nil, %{query: "xyz", limit: 10}, nil)

      assert results == []
    end

    test "returns empty list when query is shorter than 3 bytes" do
      insert(:speaker, full_name: "John Smith")

      {:ok, results} = Speakers.search_speakers(nil, %{query: "Jo"}, nil)

      assert results == []
    end

    test "respects the limit parameter" do
      insert_list(5, :speaker, full_name: "Common Name")

      {:ok, results} = Speakers.search_speakers(nil, %{query: "Common Name", limit: 2}, nil)

      assert length(results) == 2
    end
  end

  describe "search_speakers/3 — LIKE wildcard escaping" do
    test "% is treated as a literal character, not a wildcard" do
      insert(:speaker, full_name: "John Smith")

      # Without escaping, "%%%" would become "%%%%%", matching every row.
      {:ok, results} = Speakers.search_speakers(nil, %{query: "%%%", limit: 10}, nil)

      assert results == []
    end

    test "_ is treated as a literal character, not a single-char wildcard" do
      insert(:speaker, full_name: "Jo Smith")

      # Without escaping, "___" would become "%___%", matching any name with ≥ 3 chars.
      {:ok, results} = Speakers.search_speakers(nil, %{query: "___", limit: 10}, nil)

      assert results == []
    end

    test "backslash does not cause a database error and is treated literally" do
      insert(:speaker, full_name: "John Smith")

      {:ok, results} = Speakers.search_speakers(nil, %{query: "Jo\\", limit: 10}, nil)

      assert results == []
    end

    test "a literal % in a speaker name is found when explicitly searched" do
      insert(:speaker, full_name: "100% Honest")

      {:ok, results} = Speakers.search_speakers(nil, %{query: "100%", limit: 10}, nil)

      assert length(results) == 1
      assert hd(results).full_name == "100% Honest"
    end

    test "a literal _ in a speaker name is found when explicitly searched" do
      insert(:speaker, full_name: "snake_case Speaker")

      {:ok, results} = Speakers.search_speakers(nil, %{query: "snake_case", limit: 10}, nil)

      assert length(results) == 1
      assert hd(results).full_name == "snake_case Speaker"
    end
  end
end

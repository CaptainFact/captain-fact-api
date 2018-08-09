defmodule DB.StatisticsTest do
  alias DB.{Repo, Statistics, Schema}
  alias Schema.User

  import DB.Factory, only: [insert: 1, insert: 2]

  use ExUnit.Case

  describe "user_count/0" do
    test "it returns an integer" do
      user_count = Statistics.all_totals().users

      assert is_integer(user_count)
    end

    test "it is incremented by adding a user" do
      user_count = Statistics.all_totals().users
      insert(:user)
      diff = Statistics.all_totals().users - user_count

      assert diff == 1
    end

    test "it is decremented by removing a user" do
      user = insert(:user)
      user_count = Statistics.all_totals().users
      Repo.delete(user)
      diff = Statistics.all_totals().users - user_count

      assert diff == -1
    end
  end

  describe "comment_count/0" do
    test "it returns an integer" do
      comment_count = Statistics.all_totals().comments

      assert is_integer(comment_count)
    end

    test "it is incremented by adding a comment" do
      comment_count = Statistics.all_totals().comments
      insert(:comment)
      diff = Statistics.all_totals().comments - comment_count

      assert diff == 1
    end

    test "it is decremented by removing a comment" do
      comment = insert(:comment)
      comment_count = Statistics.all_totals().comments
      Repo.delete(comment)
      diff = Statistics.all_totals().comments - comment_count

      assert diff == -1
    end
  end

  describe "statement_count/0" do
    test "it returns an integer" do
      statement_count = Statistics.all_totals.statements

      assert is_integer(statement_count)
    end

    test "it is incremented by adding a statement" do
      statement_count = Statistics.all_totals.statements
      insert(:statement)
      diff = Statistics.all_totals.statements - statement_count

      assert diff == 1
    end

    test "it is decremented by removing a statement" do
      statement = insert(:statement)
      statement_count = Statistics.all_totals.statements
      Repo.delete(statement)
      diff = Statistics.all_totals.statements - statement_count

      assert diff == -1
    end
  end

  describe "source_count/0" do
    test "it returns an integer" do
      source_count = Statistics.all_totals.sources

      assert is_integer(source_count)
    end

    test "it is incremented by adding a source" do
      source_count = Statistics.all_totals.sources
      insert(:source)
      diff = Statistics.all_totals.sources - source_count

      assert diff == 1
    end

    test "it is decremented by removing a source" do
      source = insert(:source)
      source_count = Statistics.all_totals.sources
      Repo.delete(source)
      diff = Statistics.all_totals.sources - source_count

      assert diff == -1
    end
  end

  def prepare_leaderboard(_context) do
    Repo.delete_all(User)

    0..20
    |> Enum.map(fn reputation ->
      insert(:user, reputation: reputation)
    end)

    :ok
  end

  describe "leaderboard/0" do
    setup :prepare_leaderboard

    test "returns 20 users" do
      leaderboard = Statistics.leaderboard()

      assert Enum.count(leaderboard) == 20
    end

    test "returns the 20 with the best reputation" do
      leaderboard_reputation =
        Statistics.leaderboard()
        |> Enum.map(fn %{reputation: reputation} -> reputation end)

      assert leaderboard_reputation == Enum.to_list(20..1)
    end

    test "returns tuples containing {username, name, reputation}" do
      username = "El Grande Fact Checkador"
      name = "Jean-Michel Mégalo"
      # 😱 HIS REPUTATION IS OVER 9000 !!!!!
      reputation = 9001

      insert(:user, username: username, name: name, reputation: reputation)

      [top_leader | _] = Statistics.leaderboard()

      assert %User{
               username: ^username,
               name: ^name,
               reputation: ^reputation
             } = top_leader
    end
  end
end

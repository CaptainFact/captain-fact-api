defmodule DB.Type.AchievementTest do
  use ExUnit.Case

  alias DB.Type.Achievement


  test "ensure values don't change" do
    assert Achievement.get(:welcome) == 1
    assert Achievement.get(:not_a_robot) == 2
    assert Achievement.get(:help) == 3
    assert Achievement.get(:bulletproof) == 4
    assert Achievement.get(:you_are_fake_news) == 5
    assert Achievement.get(:social_networks) == 6
    assert Achievement.get(:ambassador) == 7
    assert Achievement.get(:ghostbuster) == 8 # Made a bug report
    assert Achievement.get(:famous) == 9 # Leaderboard
  end

  test "doesn't compile if bad value" do
    assert_raise FunctionClauseError, fn ->
      Achievement.get(:nopenopenope)
    end
  end
end
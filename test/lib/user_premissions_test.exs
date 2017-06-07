defmodule CaptainFact.UserPermissionsTest do
  use ExUnit.Case, async: true
  alias CaptainFact.{UserPermissions, User, UserState}
  alias UserPermissions.PermissionsError
  doctest UserPermissions

  setup do
    UserState.reset()
    :ok
  end

  setup_all do
    negative_user = %User{id: 1, reputation: -15}
    new_user = %User{id: 2, reputation: 42}
    positive_user = %User{id: 3, reputation: 80000}
    {:ok, [negative_user: negative_user, new_user: new_user, positive_user: positive_user]}
  end

  test "@min_reputations and @limitations should have the same keys" do
    limitations = Map.keys(UserPermissions.limitations)
    min_reputations = Map.keys(UserPermissions.min_reputations)
    limitations_uniq = limitations -- min_reputations
    min_reputations_uniq = min_reputations -- limitations

    assert limitations_uniq == [], "Unique in limitations: #{inspect(limitations_uniq)}"
    assert min_reputations_uniq == [], "Unique in min_reputations: #{inspect(min_reputations_uniq)}"
  end

  test "lock! passes user to given func", context do
    UserPermissions.lock!(context[:new_user], :add_comment, fn user ->
      assert context[:new_user] == user
    end)
  end

  test "lock! updates state and return func's return", context do
    user = context[:new_user]
    action = :add_comment
    expected_result = 42
    assert UserPermissions.user_nb_action_occurences(user, action) == 0
    assert UserPermissions.lock!(context[:new_user], :add_comment, fn _ -> 42 end) == expected_result
    assert UserPermissions.user_nb_action_occurences(user, action) == 1
  end

  test "if an exception is raised in func state will not be updated", context do
    user = context[:new_user]
    action = :add_comment
    assert UserPermissions.user_nb_action_occurences(user, action) == 0
    try do
      UserPermissions.lock!(user, action, fn _ ->
        raise "Oh no 😱😱😱 !"
      end)
    rescue e -> e end
    assert UserPermissions.user_nb_action_occurences(user, action) == 0
  end

  test "if an exception is raised in func lock! will re-raise it", context do
    exception_message = "Oh no 😱😱😱 !"
    assert_raise(RuntimeError, exception_message, fn ->
      UserPermissions.lock!(context[:new_user], :add_comment, fn _ ->
        raise exception_message
      end)
    end)
  end

  test "lock! ensures permissions are verified and raise exception otherwise", context do
    assert_raise(PermissionsError, "unknow action", fn ->
      UserPermissions.lock!(context[:negative_user], :ride_unicorn, fn _ -> 42 end)
    end)
    assert_raise(PermissionsError, "not enough reputation", fn ->
      UserPermissions.lock!(context[:negative_user], :vote_down, fn _ -> 42 end)
    end)

    # Check limitation
    user = context[:new_user]
    action = :add_comment
    max_occurences = UserPermissions.limitation(user, action)
    for _ <- 0..max_occurences, do: UserPermissions.record_action(user, action)
    assert_raise(PermissionsError, "limit reached", fn ->
      UserPermissions.lock!(user, action, fn _ -> 42 end)
    end)
  end

  test "running lock! concurrently isn't messing up with state", context do
    nb_threads = 5000
    user = context[:positive_user]
    action = :vote_up
    max_occurences = UserPermissions.limitation(user, action)
    Stream.repeatedly(fn ->
      Task.async(fn ->
        try do
          UserPermissions.lock!(user, action, fn _ -> 42 end)
        rescue e in PermissionsError -> e end
      end)
    end)
    |> Enum.take(nb_threads)
    |> Enum.map(&Task.await/1)
    assert UserPermissions.user_nb_action_occurences(user, action) == max_occurences
  end
end

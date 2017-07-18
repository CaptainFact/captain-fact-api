defmodule CaptainFact.UserPermissionsTest do
  use ExUnit.Case, async: true

  alias CaptainFact.{UserPermissions, UserState}
  alias CaptainFact.Web.User
  alias UserPermissions.PermissionsError

  doctest UserPermissions

  setup do
    UserState.reset()
    :ok
  end

  setup_all do
    banned_user = %User{id: 1, reputation: -4200}
    negative_user = %User{id: 1, reputation: -15}
    new_user = %User{id: 2, reputation: 42}
    positive_user = %User{id: 3, reputation: 80000}
    {:ok, [negative_user: negative_user, new_user: new_user, positive_user: positive_user,
           banned_user: banned_user]}
  end

  test "for each limitation, we must define all levels" do
    Enum.each(UserPermissions.limitations, fn {_, limitations_tuple} ->
      assert limitations_tuple |> Tuple.to_list() |> Enum.count() == UserPermissions.nb_levels()
    end)
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
    assert_raise(PermissionsError, "not_enough_reputation", fn ->
      UserPermissions.lock!(context[:negative_user], :vote_down, fn _ -> 42 end)
    end)

    # Check limitation
    user = context[:new_user]
    action = :add_comment
    max_occurences = UserPermissions.limitation(user, action)
    for _ <- 0..max_occurences, do: UserPermissions.record_action(user, action)
    assert_raise(PermissionsError, "limit_reached", fn ->
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

  test "users with too low reputation shouldn't be able to do anything", context do
    Enum.each(UserPermissions.limitations, fn {action, _} ->
      assert UserPermissions.check(context[:banned_user], action) == {:error, "not_enough_reputation"}
    end)
  end

  test "unauthorized users should never pass UserPermissions" do
    Enum.each(UserPermissions.limitations, fn {action, _} ->
      assert UserPermissions.check(nil, action) == {:error, "unauthorized"}
    end)
  end

  test "nil user will raise UserPermissions error" do
    message = "unauthorized"

    # Lock
    assert_raise(PermissionsError, message, fn ->
      UserPermissions.lock!(nil, :add_video, fn _ -> 42 end)
    end)

    # Check
    assert_raise(PermissionsError, message, fn ->
      UserPermissions.check!(nil, :add_video)
    end)
  end
end

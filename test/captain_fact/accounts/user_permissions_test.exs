defmodule CaptainFact.Accounts.UserPermissionsTest do
  use CaptainFact.DataCase

  alias CaptainFact.Accounts.{User, UserPermissions}
  alias UserPermissions.PermissionsError

  doctest UserPermissions

  setup do
    banned_user = insert(:user, %{reputation: -4200})
    negative_user = insert(:user, %{reputation: -15})
    new_user = insert(:user, %{reputation: 42})
    positive_user = insert(:user, %{reputation: 80000})
    {:ok, [negative_user: negative_user, new_user: new_user, positive_user: positive_user, banned_user: banned_user]}
  end

  test "for each limitation, we must define all levels" do
    each_limitation(fn {_, _, limitations_tuple} ->
      assert limitations_tuple |> Tuple.to_list() |> Enum.count() == UserPermissions.nb_levels()
    end)
  end

  test "lock! passes user to given func", context do
    UserPermissions.lock!(context[:new_user], :create, :comment, fn user ->
      assert context[:new_user] == user
    end)
  end

  test "lock! updates state and return func's return", context do
    user = context[:new_user]
    action_type = :create
    entity = :comment
    expected_result = 42
    assert UserPermissions.user_nb_action_occurences(user, action_type, entity) == 0
    assert UserPermissions.lock!(context[:new_user], action_type, entity, fn _ -> 42 end) == expected_result
    assert UserPermissions.user_nb_action_occurences(user, action_type, entity) == 1
  end

  test "if an exception is throwed in func state will not be updated", context do
    user = context[:new_user]
    action_type = :create
    entity = :comment
    assert UserPermissions.user_nb_action_occurences(user, action_type, entity) == 0
    try do
      UserPermissions.lock!(user, action_type, entity, fn _ ->
        raise "Oh no 😱😱😱 !"
      end)
    rescue e -> e end
    assert UserPermissions.user_nb_action_occurences(user, action_type, entity) == 0
  end

  test "if an exception is throwed in func lock! will re-throw it", context do
    exception_message = "Oh no 😱😱😱 !"
    assert_raise(RuntimeError, exception_message, fn ->
      UserPermissions.lock!(context[:new_user], :create, :comment, fn _ ->
        raise exception_message
      end)
    end)
  end

  test "lock! ensures permissions are verified and throws exception otherwise", context do
    assert_raise PermissionsError, fn -> UserPermissions.lock!(context[:negative_user], :vote_down, :comment, fn _ -> 42 end) end

    # Check limitation
    user = context[:new_user]
    action_type = :create
    entity = :comment
    max_occurences = UserPermissions.limitation(user, action_type, entity)
    for _ <- 0..max_occurences, do: UserPermissions.record_action(user, action_type, entity)
    assert_raise PermissionsError, fn -> UserPermissions.lock!(user, action_type, entity, fn _ -> 42 end) end
  end

  test "lock! must fail if we hit the limit", context do
    user = context[:positive_user]
    action_type = :vote_up
    entity = :comment
    max_occurences = UserPermissions.limitation(user, action_type, entity)
    for _ <- 1..max_occurences do
      UserPermissions.lock!(user, action_type, entity, fn _ -> 42 end)
    end
    assert_raise PermissionsError, "limit_reached", fn ->
      UserPermissions.lock!(user, action_type, entity, fn _ -> 42 end)
    end
  end

  test "running lock! concurrently isn't messing up with state", context do
    nb_threads = 500
    user = context[:positive_user]
    action_type = :vote_up
    entity = :comment
    max_occurences = UserPermissions.limitation(user, action_type, entity)
    Stream.repeatedly(fn ->
      Process.sleep(1) # To better simulate requests
      Task.async(fn ->
        try do
          UserPermissions.lock!(user, action_type, entity, fn _ -> 42 end)
        rescue e in PermissionsError -> e end
      end)
    end)
    |> Enum.take(nb_threads)
    |> Enum.map(&Task.await/1)
    assert UserPermissions.user_nb_action_occurences(user, action_type, entity) == max_occurences
  end

  test "users with too low reputation shouldn't be able to do anything", context do
    each_limitation(fn {action_type, entity, _} ->
      assert UserPermissions.check(context[:banned_user], action_type, entity) == {:error, "not_enough_reputation"}
    end)
  end

  test "unauthorized users should never pass UserPermissions" do
    each_limitation(fn {action_type, entity, _} ->
      assert UserPermissions.check(nil, action_type, entity) == {:error, "unauthorized"}
    end)
  end

  test "nil user will throw UserPermissions error" do
    # Lock
    assert_raise PermissionsError, fn -> UserPermissions.lock!(nil, :add, :video, fn _ -> 42 end) end

    # Check
    assert_raise PermissionsError, fn -> UserPermissions.check!(nil, :add, :video) end
  end

  defp each_limitation(func) do
    for {action_type, entities_limitations} <- UserPermissions.limitations do
      for {entity, limitation} <- entities_limitations do
        func.({action_type, entity, limitation})
      end
    end
  end
end

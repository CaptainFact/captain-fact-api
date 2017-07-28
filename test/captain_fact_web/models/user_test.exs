defmodule CaptainFact.UserTest do
  use CaptainFact.DataCase, async: true

  alias CaptainFact.Accounts.User

  @valid_attrs %{
    name: "Jouje BigBrother",
    username: "Hell0World 🌳",
    email: Faker.Internet.email,
    password: "@StrongP4ssword!"
  }
  @invalid_attrs %{}

  def valid_attrs(), do: @valid_attrs

  test "registration changeset with valid attributes" do
    changeset = User.registration_changeset(%User{}, @valid_attrs)
    assert changeset.valid?
  end

  test "registration changeset with invalid attributes" do
    changeset = User.registration_changeset(%User{}, @invalid_attrs)
    refute changeset.valid?
  end

  test "username should be between 5 and 15 characters" do
    # Too short
    attrs = %{username: "x"}
    assert {:username, "should be at least 5 character(s)"} in errors_on(%User{}, attrs)

    # Too long
    attrs = %{username: String.duplicate("x", 16)}
    assert {:username, "should be at most 15 character(s)"} in errors_on(%User{}, attrs)
  end

  test "name must be between 2 and 20 characters" do
    # Too short
    attrs = %{name: "x"}
    assert {:name, "should be at least 2 character(s)"} in errors_on(%User{}, attrs)

    # Too long
    attrs = %{name: String.duplicate("x", 21)}
    assert {:name, "should be at most 20 character(s)"} in errors_on(%User{}, attrs)
  end

  test "password must be between 6 and 256 characters" do
    # Too short
    attrs = %{password: "x"}
    assert {:password, "should be at least 6 character(s)"} in errors_on(%User{}, attrs)

    # Too long
    attrs = %{password: String.duplicate("x", 257)}
    assert {:password, "should be at most 256 character(s)"} in errors_on(%User{}, attrs)
  end

  test "email must be a valid address" do
    changeset = User.registration_changeset(%User{}, Map.put(@valid_attrs, :email, "INVALID EMAIL"))
    refute changeset.valid?
  end

  test "email must not be a temporary email (yopmail, jetable.org...etc)" do
    provider = Enum.random(ForbiddenEmailProviders.get_temporary_providers)
    attrs = %{email: "#{Faker.Internet.user_name}@#{provider}"}
    assert {:email, "forbidden_provider"} in errors_on(%User{}, attrs)
  end

  test "username should not contains forbidden passwords" do
    changeset = User.registration_changeset(%User{}, %{@valid_attrs | username: "toto-Admin"})
    refute changeset.valid?

    changeset = User.registration_changeset(%User{}, %{@valid_attrs | username: "toCaptainFactto"})
    refute changeset.valid?
  end
end

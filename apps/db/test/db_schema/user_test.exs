defmodule DB.Schema.UserTest do
  use DB.DataCase, async: true

  import DB.Factory, only: [insert: 1, insert: 2]
  alias DB.Schema.User

  @valid_attrs %{
    name: "Jouje BigBrother",
    username: "Hell0World",
    email: Faker.Internet.email(),
    password: "@StrongP4ssword!",
    locale: "en"
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
    changeset = User.registration_changeset(%User{}, Map.put(@valid_attrs, :email, "xx@xx"))
    refute changeset.valid?
  end

  test "email must not be a temporary email (yopmail, jetable.org...etc)" do
    provider = "jetable.org"
    attrs = %{email: "xxxxx@#{provider}"}

    assert {:email, "forbidden_provider"} in errors_on(%User{}, attrs),
           "didn't reject #{provider}'"
  end

  test "username should not contains forbidden words" do
    changeset = User.registration_changeset(%User{}, %{@valid_attrs | username: "toto-Admin"})
    refute changeset.valid?

    changeset =
      User.registration_changeset(%User{}, %{@valid_attrs | username: "toCaptainFactto"})

    refute changeset.valid?
  end

  test "username cannot contains illegal characters" do
    ' !*();:@&=+$,/?#[].\'\\'
    |> Enum.map(fn char ->
      changeset =
        User.registration_changeset(%User{}, %{
          @valid_attrs
          | username: "x42xxx#{<<char::utf8>>}xx"
        })

      refute changeset.valid?,
             "Illegal character '#{<<char::utf8>>}' accepted in username when it should not"
    end)
  end

  test "name cannot contains illegal characters" do
    '!*();:@&=+$,/?#[].\'\\0123456789'
    |> Enum.map(fn char ->
      changeset =
        User.registration_changeset(%User{}, %{@valid_attrs | name: "xxxx#{<<char::utf8>>}xx"})

      refute changeset.valid?,
             "Illegal character '#{<<char::utf8>>}' accepted in name when it should not"
    end)
  end

  test "name can contain a space" do
    changeset = User.registration_changeset(%User{}, %{@valid_attrs | name: "David Gilmour"})
    assert changeset.valid?
  end

  test "name can contain accentuated characters" do
    changeset = User.registration_changeset(%User{}, %{@valid_attrs | name: "Jésus"})
    assert changeset.valid?
  end

  test "name and username are trim" do
    changeset =
      User.registration_changeset(%User{}, %{
        @valid_attrs
        | name: "    test  test  ",
          username: "    testtest "
      })

    assert changeset.valid?
    assert changeset.changes.name == "test test"
    assert changeset.changes.username == "testtest"
  end

  test "name can be empty or nil" do
    changeset = User.registration_changeset(%User{}, %{@valid_attrs | name: ""})
    assert changeset.valid?

    changeset = User.registration_changeset(%User{}, %{@valid_attrs | name: nil})
    assert changeset.valid?
  end

  test "characters _ and - are still allowed in username" do
    changeset = User.registration_changeset(%User{}, %{@valid_attrs | username: "xxxxxxx-y"})
    changeset2 = User.registration_changeset(%User{}, %{@valid_attrs | username: "xxxxxxx_y"})
    assert changeset.valid?
    assert changeset2.valid?
  end

  test "locale get verified and set to default if invalid" do
    changeset = User.changeset(%User{}, %{@valid_attrs | locale: "FR"})
    assert changeset.changes.locale == "fr"

    changeset = User.changeset(%User{}, %{@valid_attrs | locale: "en"})
    assert changeset.changes.locale == "en"

    changeset = User.changeset(%User{}, %{@valid_attrs | locale: "xxoooxx"})
    assert changeset.changes.locale == "en"
  end

  test "default user should not be a publisher" do
    changeset = User.registration_changeset(%User{}, @valid_attrs)
    refute changeset.data.is_publisher
  end

  test "achievements changeset ensure achievements are unique" do
    changeset = User.changeset_achievement(%User{achievements: [1, 1, 1, 3, 8, 8, 5, 6, 6]}, 4)
    assert changeset.changes.achievements == [4, 1, 3, 8, 5, 6]
  end

  test "empty changeset if no changes in achievements" do
    changeset = User.changeset_achievement(%User{achievements: [1, 1, 1, 3, 8, 8, 5, 6, 6]}, 3)
    refute changeset.changes[:achievements]
  end

  test "changeset_link_speaker generate a changeset with linked speaker" do
    user = insert(:user, speaker: nil)
    speaker = insert(:speaker)
    changeset = User.changeset_link_speaker(user, speaker)
    assert changeset.changes.speaker.data.id == speaker.id
  end
end

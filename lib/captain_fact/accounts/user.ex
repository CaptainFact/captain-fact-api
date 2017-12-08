defmodule CaptainFact.Accounts.User do
  use Ecto.Schema
  use Arc.Ecto.Schema
  import Ecto.Changeset

  alias CaptainFact.TokenGenerator
  alias CaptainFact.Accounts.{ForbiddenEmailProviders, Achievement}


  schema "users" do
    field :username, :string
    field :email, :string
    field :encrypted_password, :string
    field :name, :string
    field :picture_url, CaptainFact.Accounts.UserPicture.Type
    field :reputation, :integer, default: 0
    field :today_reputation_gain, :integer, default: 0
    field :locale, :string
    field :achievements, {:array, :integer}, default: []
    field :newsletter, :boolean, default: true
    field :newsletter_subscription_token, :string

    # Social networks profiles
    field :fb_user_id, :string

    # Email Confirmation
    field :email_confirmed, :boolean, default: false
    field :email_confirmation_token, :string

    # Virtual
    field :password, :string, virtual: true

    # Assocs
    has_many :actions, CaptainFact.Actions.UserAction, on_delete: :delete_all
    has_many :comments, CaptainFact.Comments.Comment, on_delete: :delete_all
    has_many :votes, CaptainFact.Comments.Vote, on_delete: :delete_all

    has_many :flags_posted, CaptainFact.Actions.Flag, foreign_key: :source_user_id, on_delete: :delete_all

    timestamps()
  end

  def user_appelation(%{username: username, name: nil}), do: "@#{username}"
  def user_appelation(%{username: username, name: name}), do: "#{name} (@#{username})"

  @email_regex ~r/\A([\w+\-].?)+@[a-z\d\-]+(\.[a-z]+)*\.[a-z]+\z/i
  @valid_locales ~w(en fr de it es ru)
  @required_fields ~w(email username)a
  @optional_fields ~w(name password locale)a

  def email_regex(), do: @email_regex

  @doc """
  Creates a changeset based on the `model` and `params`.
  If no params are provided, an invalid changeset is returned
  with no validation performed.
  """
  def changeset(model, params \\ %{}) do
    model
    |> common_changeset(params)
    |> validate_length(:password, min: 6, max: 256)
    |> put_encrypted_pw
  end

  @doc"""
  Generate a changeset to update `reputation` and `today_reputation_gain` without verifying daily limits
  """
  def reputation_changeset(model = %{reputation: reputation, today_reputation_gain: today_gain}, change)
  when is_integer(change) do
    change(model, %{reputation: reputation + change, today_reputation_gain: today_gain + change})
  end

  def registration_changeset(model, params \\ %{}) do
    model
    |> common_changeset(params)
    |> password_changeset(params)
    |> generate_email_verification_token(false)
    |> put_change(:achievements, [Achievement.get(:welcome)]) # Default to "welcome" achievement
  end

  def changeset_confirm_email(model, is_confirmed) do
    model
    |> change(email_confirmed: is_confirmed)
    |> generate_email_verification_token(is_confirmed)
  end

  def password_changeset(model, params) do
    model
    |> cast(params, [:password])
    |> validate_required([:password])
    |> validate_length(:password, min: 6, max: 256)
    |> put_encrypted_pw
  end

  def provider_changeset(model, params \\ %{}) do
    cast(model, params, [:fb_user_id])
  end

  @token_length 32
  defp generate_email_verification_token(changeset, false),
    do: put_change(changeset, :email_confirmation_token, TokenGenerator.generate(@token_length))
  defp generate_email_verification_token(changeset, true),
    do: put_change(changeset, :email_confirmation_token, nil)

  defp common_changeset(model, params) do
    model
    |> cast(params, @required_fields ++ @optional_fields)
    |> validate_required(@required_fields)
    |> unique_constraint(:email)
    |> unique_constraint(:username)
    |> validate_length(:username, min: 5, max: 15)
    |> validate_length(:name, min: 2, max: 20)
    |> validate_inclusion(:locale, @valid_locales)
    |> validate_email()
    |> validate_username()
  end

  defp put_encrypted_pw(changeset) do
    case changeset do
      %Ecto.Changeset{valid?: true, changes: %{password: pass}} ->
        changeset
        |> put_change(:encrypted_password, Comeonin.Bcrypt.hashpwsalt(pass))
        |> delete_change(:password)
      _ ->
        changeset
    end
  end

  def validate_email(%{changes: %{email: email}} = changeset) do
    case Regex.match?(@email_regex, email) do
      true ->
        case ForbiddenEmailProviders.is_forbidden?(email) do
          true -> add_error(changeset, :email, "forbidden_provider")
          false -> changeset
        end
      false -> add_error(changeset, :email, "invalid_format")
    end
  end
  def validate_email(changeset), do: changeset

  @forbidden_username_keywords ~w(captainfact captain admin newuser temporary anonymous)
  @username_regex ~r/^[a-zA-Z0-9-_]+$/ # Only alphanum, '-' and '_'
  defp validate_username(%{changes: %{username: username}} = changeset) do
    lower_username = String.downcase(username)
    case Enum.find(@forbidden_username_keywords, &String.contains?(lower_username, &1)) do
      nil -> validate_format(changeset, :username, @username_regex)
      keyword -> add_error(changeset, :username, "contains a foridden keyword: #{keyword}")
    end
  end
  defp validate_username(changeset), do: changeset
end

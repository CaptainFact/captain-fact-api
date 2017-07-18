defmodule CaptainFact.Web.User do
  use CaptainFact.Web, :model

  schema "users" do
    field :name, :string
    field :username, :string
    field :email, :string
    field :encrypted_password, :string
    field :reputation, :integer, null: false, default: 0

    field :password, :string, virtual: true

    has_many :comments, CaptainFact.Web.Comment, on_delete: :delete_all
    has_many :votes, CaptainFact.Web.Vote, on_delete: :delete_all
    has_many :video_debate_actions, CaptainFact.Web.VideoDebateAction, on_delete: :nilify_all

    has_many :flags_posted, CaptainFact.Web.Flag, foreign_key: :source_user_id, on_delete: :nothing
    has_many :flags_received, CaptainFact.Web.Flag, foreign_key: :target_user_id, on_delete: :nothing

    timestamps()
  end


  @required_fields ~w(email username)a
  @optional_fields ~w(name password)a

  @doc """
  Creates a changeset based on the `model` and `params`.
  If no params are provided, an invalid changeset is returned
  with no validation performed.
  """
  def changeset(model, params \\ :empty) do
    model
    |> common_changeset(params)
    |> validate_length(:password, min: 6, max: 256)
    |> put_encrypted_pw
  end

  def reputation_changeset(model, params) do
    model
    |> cast(params, [:reputation])
  end

  def registration_changeset(model, params \\ :empty) do
    model
    |> common_changeset(params)
    |> validate_required([:password])
    |> validate_length(:password, min: 6, max: 256)
    |> put_encrypted_pw
  end

  defp common_changeset(model, params) do
    model
    |> cast(params, @required_fields ++ @optional_fields)
    |> validate_required(@required_fields)
    |> unique_constraint(:email)
    |> unique_constraint(:username)
    |> validate_length(:username, min: 5, max: 15)
    |> validate_length(:name, min: 2, max: 20)
    |> validate_email()
    |> validate_username()
  end

  defp put_encrypted_pw(changeset) do
    case changeset do
      %Ecto.Changeset{valid?: true, changes: %{password: pass}} ->
        put_change(changeset, :encrypted_password, Comeonin.Bcrypt.hashpwsalt(pass))
      _ ->
        changeset
    end
  end

  defp validate_email(%{changes: %{email: email}} = changeset) do
    case Regex.match?(~r/@/, email) do
      true ->
        case ForbiddenEmailProviders.is_forbidden(email) do
          true -> add_error(changeset, :email, "this email provider is forbidden")
          false -> changeset
        end
      false -> add_error(changeset, :email, "invalid format")
    end
  end
  defp validate_email(changeset), do: changeset

  @forbidden_username_keywords ~w(captainfact admin newuser temporary anonymous)
  defp validate_username(%{changes: %{username: username}} = changeset) do
    lower_username = String.downcase(username)
    case Enum.find(@forbidden_username_keywords, &String.contains?(lower_username, &1)) do
      nil -> changeset
      keyword -> add_error(changeset, :username, "contains a foridden keyword: #{keyword}")
    end
  end
  defp validate_username(changeset), do: changeset
end

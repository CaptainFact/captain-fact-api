defmodule CaptainFact.User do
  use CaptainFact.Web, :model

  schema "users" do
    field :name, :string
    field :username, :string
    field :email, :string
    field :encrypted_password, :string

    field :password, :string, virtual: true

    has_many :videos, CaptainFact.Video, foreign_key: :owner_id
    has_many :comments, CaptainFact.Comment

    many_to_many :administered_videos, CaptainFact.Video, join_through: VideoAdmin, on_delete: :delete_all, on_replace: :delete

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

  def registration_changeset(model, params \\ :empty) do
    #TODO Validate real email and not yopmail...etc
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
    |> validate_email()
    |> unique_constraint(:email)
    |> validate_length(:username, min: 3, max: 20)
    |> validate_length(:name, min: 2, max: 30)
    |> unique_constraint(:username)
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
end

defmodule CaptainFact.User do
  use CaptainFact.Web, :model

  alias CaptainFact.Repo

  schema "users" do
    field :name, :string
    field :username, :string
    field :email, :string
    field :encrypted_password, :string

    field :password, :string, virtual: true

    timestamps()
  end


  @required_fields ~w(email username)a
  @optional_fields ~w(name)a

  @doc """
  Creates a changeset based on the `model` and `params`.
  If no params are provided, an invalid changeset is returned
  with no validation performed.
  """
  def changeset(model, params \\ :empty) do
    model
    |> cast(params, @required_fields ++ @optional_fields)
    |> validate_required(@required_fields)
    |> validate_format(:email, ~r/@/)
    |> unique_constraint(:email)
    |> validate_length(:username, min: 3, max: 30)
    |> unique_constraint(:username)
  end

  def registration_changeset(model, params \\ :empty) do
    model
    |> changeset(params)
    |> cast(params, ~w(password))
    |> validate_length(:password, min: 6, max: 100)
    |> put_encrypted_pw
  end

  defp put_encrypted_pw(changeset) do
    case changeset do
      %Ecto.Changeset{valid?: true, changes: %{password: pass}} ->
        put_change(changeset, :encrypted_password, Comeonin.Bcrypt.hashpwsalt(pass))
      _ ->
        changeset
    end
  end
end

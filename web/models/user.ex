defmodule CaptainFact.User do
  use CaptainFact.Web, :model

  alias CaptainFact.Repo

  schema "users" do
    field :name, :string
    field :nickname, :string
    field :email, :string

    has_many :authorizations, CaptainFact.Authorization

    timestamps()
  end


  @required_fields ~w(email nickname)a
  @optional_fields ~w(name)a

  def registration_changeset(model, params \\ :empty) do
    model
    |> cast(params, ~w(email nickname)a)
    |> validate_required(@required_fields)
  end

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
    |> validate_length(:nickname, min: 3, max: 30)
    |> update_change(:nickname, &String.downcase/1)
    |> unique_constraint(:nickname)
  end
end

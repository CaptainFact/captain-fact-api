defmodule DB.Schema.InvitationRequest do
  use Ecto.Schema
  import Ecto.Changeset

  alias DB.Schema.User
  alias DB.Schema.InvitationRequest


  schema "invitation_requests" do
    field :email, :string
    field :invitation_sent, :boolean, default: false
    field :token, :string
    field :locale, :string

    belongs_to :invited_by, User

    timestamps()
  end

  @doc false
  def changeset(invitation_request = %InvitationRequest{}, attrs) do
    invitation_request
    |> cast(attrs, [:email, :invited_by_id, :locale])
    |> validate_required([:email])
    |> User.validate_email()
    |> User.validate_locale()
    |> unique_constraint(:email)
  end

  def changeset_token(request, token) do
    change(request, token: token)
  end

  def changeset_sent(request, is_sent) do
    change(request, invitation_sent: is_sent)
  end
end

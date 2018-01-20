defmodule DB.Schema.ResetPasswordRequest do
  use Ecto.Schema
  import Ecto.Changeset


  @primary_key {:token, :string, []}
  @derive {Phoenix.Param, key: :token}
  schema "accounts_reset_password_requests" do
    field :source_ip, :string
    belongs_to :user, DB.Schema.User

    timestamps(updated_at: false)
  end

  @token_length 128

  def changeset(model, attrs) do
    model
    |> cast(attrs, [:source_ip, :user_id])
    |> change(token: DB.Utils.TokenGenerator.generate(@token_length))
    |> validate_required([:source_ip, :user_id, :token])
  end
end

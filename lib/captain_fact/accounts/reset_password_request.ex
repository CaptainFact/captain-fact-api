defmodule CaptainFact.Accounts.ResetPasswordRequest do
  use Ecto.Schema
  import Ecto.Changeset
  alias CaptainFact.Accounts.ResetPasswordRequest


  @primary_key {:token, :string, []}
  @derive {Phoenix.Param, key: :token}
  schema "accounts_reset_password_requests" do
    field :source_ip, :string
    field :user_id, :id

    timestamps(updated_at: false)
  end

  def changeset(model, attrs) do
    model
    |> cast(attrs, [:source_ip, :user_id])
    |> change(token: generate_unique_token())
    |> validate_required([:source_ip, :user_id, :token])
  end

  @token_length 254
  defp generate_unique_token() do
    :crypto.strong_rand_bytes(@token_length)
    |> Base.url_encode64
    |> binary_part(0, @token_length)
  end
end

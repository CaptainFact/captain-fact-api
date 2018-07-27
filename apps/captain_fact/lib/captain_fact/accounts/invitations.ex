defmodule CaptainFact.Accounts.Invitations do
  @moduledoc """
  Invitation system. Generate invites, validate them...

  Can be bypassed by setting the {:captain_fact, :invitation_system} env variable
  to false. This configuration can safely be modified at runtime.
  """

  require Logger
  import Ecto.Query

  alias DB.Utils.TokenGenerator
  alias DB.Schema.InvitationRequest
  alias DB.Schema.User
  alias DB.Repo

  @default_token_length 8

  @doc """
  Returns true if invitation system is enabled, false otherwise
  """
  def enabled?, do: Application.get_env(:captain_fact, :invitation_system)

  @doc """
  Enable the invitation system
  """
  def enable, do: Application.put_env(:captain_fact, :invitation_system, true)

  @doc """
  Disable the invitation system
  """
  def disable, do: Application.put_env(:captain_fact, :invitation_system, false)

  @doc """
  Returns true if invitation can be safely consumed, false otherwise.

  Always returns true is invitation system is disabled.
  """
  def invitation_valid?(invitation) do
    if enabled?(), do: do_invitation_valid?(invitation), else: true
  end

  defp do_invitation_valid?(nil),
    do: false

  defp do_invitation_valid?(%InvitationRequest{token: token}),
    do: do_invitation_valid?(token)

  defp do_invitation_valid?(token) when is_binary(token),
    do: not is_nil(get_invitation_for_token(token))

  @doc """
  Consume one invitation for given `invitation_token`. We willingly delete token
  using `invitation_token` string because we accept having multiple invitations
  with the same token.
  """
  def consume_invitation(%InvitationRequest{token: token}),
    do: consume_invitation(token)

  def consume_invitation(invitation_token)
  when is_binary(invitation_token) do
    case get_invitation_for_token(invitation_token) do
      nil ->
        {:error, "invalid_invitation_token"}

      invit ->
        Repo.delete(invit)
        Logger.debug(fn ->
          "Invitation #{invit.id} for token #{invit.token} has been consumed"
        end)
        {:ok, invitation_token}
    end
  end

  # --------

  @doc """
  Request an invitation for given email
  """
  def request_invitation(email, invited_by_id \\ nil, locale \\ nil)

  def request_invitation(email, invited_by_id, locale)
      when is_nil(invited_by_id) or is_integer(invited_by_id) do
    with true <- Regex.match?(User.email_regex(), email),
         false <- Burnex.is_burner?(email) do
      case Repo.get_by(InvitationRequest, email: email) do
        nil ->
          %InvitationRequest{}
          |> InvitationRequest.changeset(%{
            email: email,
            invited_by_id: invited_by_id,
            locale: locale
          })
          |> Repo.insert()

        %{invitation_sent: true} = invit ->
          Repo.update(InvitationRequest.changeset_sent(invit, false))

        request ->
          {:ok, request}
      end
    else
      _ -> {:error, "invalid_email"}
    end
  end

  def request_invitation(email, %User{id: id}, locale),
    do: request_invitation(email, id, locale)

  @doc """
  Send `nb_invites` invitations to most recently updated users
  """
  def send_invites(nb_invites) do
    InvitationRequest
    |> where([i], not is_nil(i.email))
    |> where([i], i.invitation_sent == false)
    |> order_by([i], i.updated_at)
    |> preload(:invited_by)
    |> limit(^nb_invites)
    |> Repo.all()
    |> Enum.each(&send_invite/1)
  end

  @doc """
  Send invite to the given email or invitation request
  """
  def send_invite(email) when is_binary(email) do
    {:ok, request} = request_invitation(email)
    send_invite(request)
  end

  def send_invite(request = %InvitationRequest{token: nil}) do
    request
    |> InvitationRequest.changeset_token(TokenGenerator.generate(@default_token_length))
    |> Repo.update!()
    |> send_invite()
  end

  def send_invite(request = %InvitationRequest{}) do
    request
    |> Repo.preload(:invited_by)
    |> CaptainFactMailer.Email.invitation_to_register()
    |> CaptainFactMailer.deliver_later()

    # Email sent successfuly
    Repo.update!(InvitationRequest.changeset_sent(request, true))
  end

  @doc """
  Generate `number` invitations. You can specify a custom `token`
  """
  def generate_invites(number),
    do: generate_invites(number, TokenGenerator.generate(@default_token_length))

  def generate_invites(number, token) do
    time = Ecto.DateTime.utc()

    Repo.insert_all(
      InvitationRequest,
      for(_ <- 1..number, do: %{token: token, inserted_at: time, updated_at: time})
    )

    frontend_url = Application.fetch_env!(:captain_fact, :frontend_url)

    Logger.info(
      "Generated #{number} invites for token #{token}. Url: #{frontend_url}/signup?invitation_token=#{
        token
      }"
    )
  end

  @doc """
  Return an invitation for given token, or nil if token is invalid
  """
  def get_invitation_for_token(token) do
    InvitationRequest
    |> where(token: ^token)
    |> limit(1)
    |> Repo.one()
  end
end

defmodule DB.Factory do
  @moduledoc"""
  Build mock entities easilly. Only in dev / test
  """

  use ExMachina.Ecto, repo: DB.Repo
  import Ecto.Query

  alias DB.Repo
  alias DB.Schema.Source
  alias DB.Schema.User
  alias DB.Schema.InvitationRequest
  alias DB.Schema.UserAction
  alias DB.Schema.Video
  alias DB.Schema.Comment
  alias DB.Schema.Vote
  alias DB.Schema.Speaker
  alias DB.Schema.Statement
  alias DB.Schema.Flag
  alias DB.Schema.ResetPasswordRequest


  def user_factory do
    %User{
      name: Faker.Name.first_name,
      username: "User-#{random_string(10)}",
      email: Faker.Internet.email,
      encrypted_password: "$2b$12$fe55IfCdqNzKp1wMIJDwVeG3f7guOduEE5HS2C9IJyfkuk3avbjQG",
      fb_user_id: Integer.to_string(Enum.random(10_000..999_999_999_999_999)),
      reputation: 0,
      email_confirmation_token: random_string(64),
      achievements: [1], # Users are always created with the "Welcome" achievement
      today_reputation_gain: 0,
      newsletter_subscription_token: random_string(32),
      is_publisher: false
    }
  end

  def video_factory do
    youtube_id = random_string(11)
    %Video{
      url: "https://www.youtube.com/watch?v=#{youtube_id}",
      title: random_string(10),
      provider: "youtube",
      provider_id: youtube_id
    }
  end

  def speaker_factory do
    %Speaker{
      full_name: Faker.Name.name,
      title: Faker.Name.title,
      country: Faker.Address.country_code,
      is_user_defined: Enum.random([true, false]),
    }
  end

  def statement_factory do
    %Statement{
      text: Faker.Lorem.sentence(6..10),
      time: Enum.random(1..1000),
      video: build(:video),
      speaker: Enum.random([nil, build(:speaker)])
    }
  end

  def comment_factory do
    %Comment{
      text: Faker.Lorem.sentence(0..10),
      approve: Enum.random([false, true, nil]),
      statement: build(:statement),
      user: build(:user)
    }
  end

  def invitation_request_factory do
    %InvitationRequest{
      email: Faker.Internet.email,
      invited_by: build(:user),
      token: "TestToken-" <> random_string(8)
    }
  end

  def source_factory do
    %Source{
      url: Faker.Internet.url,
      site_name: Faker.Internet.domain_word,
      language: String.downcase(Faker.Address.country_code),
      title: Faker.Lorem.sentence(1..10)
    }
  end

  def vote_factory do
    %Vote{
      user: build(:user),
      comment: build(:comment),
      value: 1
    }
  end

  def user_action_factory do
    %UserAction{
      user: build(:user),
      target_user: build(:user),
      context: "FACTORY",
      type: UserAction.type(:create),
      entity: UserAction.entity(:comment),
      entity_id: nil,
      changes: nil
    }
  end

  def flag_factory do
    %Flag{
      source_user: build(:user),
      action: build(:user_action),
      reason: 1
    }
  end

  def reset_password_request_factory do
    %ResetPasswordRequest{
      user: build(:user),
      token: "TestToken-" <> random_string(8),
      source_ip: Enum.random([Faker.Internet.ip_v4_address, Faker.Internet.ip_v6_address])
    }
  end

  # ---- Helpers ----

  def with_action(comment = %Comment{}) do
    comment = DB.Repo.preload(comment, [:user, :source])
    insert(:user_action, %{
      user: comment.user,
      type: UserAction.type(:create),
      context: UserAction.video_debate_context(comment.statement.video_id),
      entity: UserAction.entity(:comment),
      entity_id: comment.id,
      changes: %{
        text: comment.text,
        source: comment.source && comment.source.url,
        statement_id: comment.statement.id,
        reply_to_id: comment.reply_to_id
      }
    })
    comment
  end

  @action_flag UserAction.type(:flag)
  def with_action(flag = %Flag{}) do
    flag = DB.Repo.preload(flag, :source_user)
    flag = DB.Repo.preload(flag, :action)
    insert(:user_action, %{
      user: flag.source_user,
      type: @action_flag,
      entity: flag.action.entity,
      entity_id: flag.action.entity_id
    })
    flag
  end

  @action_create UserAction.type(:create)
  @entity_comment UserAction.entity(:comment)
  def flag(comment = %Comment{}, nb_flags, reason \\ 1) do
    action =
      UserAction
      |> where([a], a.type == ^@action_create)
      |> where([a], a.entity == ^@entity_comment)
      |> where([a], a.entity_id == ^comment.id)
      |> Repo.one!()

    Enum.take(
      Stream.repeatedly(fn ->
        with_action insert(:flag, %{
          action: action,
          reason: reason
        })
      end),
      nb_flags
    )
    comment
  end

  defp random_string(length) do
    :crypto.strong_rand_bytes(length)
    |> Base.url_encode64
    |> binary_part(0, length)
  end
end
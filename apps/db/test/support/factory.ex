defmodule DB.Factory do
  @moduledoc """
  Build mock entities easilly. Only in dev / test
  """

  use ExMachina.Ecto, repo: DB.Repo
  import Ecto.Query

  alias DB.Repo
  alias DB.Type.VideoHashId
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
  alias DB.Schema.Subscription
  alias DB.Schema.Notification

  def user_factory do
    %User{
      name: Faker.Name.first_name(),
      username: "User-#{random_string(10)}",
      email: Faker.Internet.email(),
      encrypted_password: "$2b$12$fe55IfCdqNzKp1wMIJDwVeG3f7guOduEE5HS2C9IJyfkuk3avbjQG",
      fb_user_id: nil,
      reputation: 0,
      email_confirmation_token: random_string(64),
      # Users are always created with the "Welcome" achievement
      achievements: [1],
      today_reputation_gain: 0,
      newsletter_subscription_token: random_string(32),
      is_publisher: false
    }
  end

  def with_fb_user_id(user = %User{}) do
    %{
      user
      | fb_user_id: Kaur.Secure.generate_api_key()
    }
  end

  def video_factory do
    youtube_id = random_string(11)

    %Video{
      url: "https://www.youtube.com/watch?v=#{youtube_id}",
      title: Faker.Lorem.sentence(3..8),
      youtube_id: youtube_id,
      hash_id: nil,
      language: Enum.random(["en", "fr", nil])
    }
  end

  def with_video_hash_id(video = %Video{id: id}) do
    Repo.update!(Ecto.Changeset.change(video, hash_id: VideoHashId.encode(id)))
  end

  def speaker_factory do
    %Speaker{
      full_name: Faker.Name.name(),
      title: Faker.Name.title(),
      country: Faker.Address.country_code()
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
      email: Faker.Internet.email(),
      invited_by: build(:user),
      token: "TestToken-" <> random_string(8)
    }
  end

  def source_factory do
    %Source{
      url: "#{Faker.Internet.url()}/#{random_string(4)}",
      site_name: Faker.Internet.domain_word(),
      language: String.downcase(Faker.Address.country_code()),
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
      type: :create,
      entity: :comment,
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
      source_ip: Enum.random([Faker.Internet.ip_v4_address(), Faker.Internet.ip_v6_address()])
    }
  end

  def subscription_factory do
    %Subscription{
      user: build(:user),
      video: build(:video),
      scope: :video
    }
  end

  def notification_factory do
    %Notification{
      user: build(:user),
      action: build(:user_action),
      type: :default
    }
  end

  # ---- Helpers ----

  def with_action(comment = %Comment{}) do
    comment = DB.Repo.preload(comment, [:user, :source, :statement])

    insert(:user_action, %{
      user: comment.user,
      type: :create,
      entity: :comment,
      video_id: comment.statement.video_id,
      statement_id: comment.statement.id,
      comment_id: comment.id,
      changes: %{
        text: comment.text,
        source: comment.source && comment.source.url,
        statement_id: comment.statement.id,
        reply_to_id: comment.reply_to_id
      }
    })

    comment
  end

  def with_action(flag = %Flag{}) do
    flag = DB.Repo.preload(flag, :source_user)
    flag = DB.Repo.preload(flag, :action)

    insert(:user_action, %{
      user: flag.source_user,
      type: :flag,
      entity: flag.action.entity,
      comment_id: flag.action.comment_id
    })

    flag
  end

  def flag(comment = %Comment{}, nb_flags, reason \\ 1) do
    action =
      UserAction
      |> where([a], a.type == ^:create)
      |> where([a], a.entity == ^:comment)
      |> where([a], a.comment_id == ^comment.id)
      |> Repo.one!()

    # credo:disable-for-next-line
    Enum.take(
      Stream.repeatedly(fn ->
        with_action(
          insert(:flag, %{
            action: action,
            reason: reason
          })
        )
      end),
      nb_flags
    )

    comment
  end

  def random_string(length) do
    DB.Utils.TokenGenerator.generate(length)
  end
end

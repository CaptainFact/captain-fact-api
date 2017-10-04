defmodule CaptainFact.Factory do
  use ExMachina.Ecto, repo: CaptainFact.Repo

  alias CaptainFact.Accounts.{User, InvitationRequest}
  alias CaptainFactWeb.{Video, Statement, Speaker}
  alias CaptainFact.Comments.{Comment, Vote}
  alias CaptainFact.Sources.Source


  def user_factory do
    %User{
      name: Faker.Name.first_name,
      username: "User-#{random_string(10)}",
      email: Faker.Internet.email,
      encrypted_password: "$2b$12$fe55IfCdqNzKp1wMIJDwVeG3f7guOduEE5HS2C9IJyfkuk3avbjQG",
      fb_user_id: Integer.to_string(Enum.random(10000..9999999999999)),
      reputation: 0,
      email_confirmation_token: random_string(64),
      achievements: [1] # Users are always created with the "Welcome" achievement
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
      token: "TestInvitationToken"
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

  defp random_string(length) do
    :crypto.strong_rand_bytes(length)
    |> Base.url_encode64
    |> binary_part(0, length)
  end
end
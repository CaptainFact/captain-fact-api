defmodule CaptainFact.Factory do
  use ExMachina.Ecto, repo: CaptainFact.Repo

  alias CaptainFactWeb.{User, Video}

  def user_factory do
    %User{
      name: "Jouje BigBrother",
      username: "User-#{random_string(10)}",
      email: Faker.Internet.email,
      encrypted_password: "$2b$12$fe55IfCdqNzKp1wMIJDwVeG3f7guOduEE5HS2C9IJyfkuk3avbjQG",
      fb_user_id: Integer.to_string(Enum.random(10000..9999999999999)),
      reputation: 0
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

  defp random_string(length) do
    :crypto.strong_rand_bytes(length)
    |> Base.url_encode64
    |> binary_part(0, length)
  end
end
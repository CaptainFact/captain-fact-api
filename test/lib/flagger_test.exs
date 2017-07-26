defmodule CaptainFact.FlaggerTest do
  use ExUnit.Case, async: false

  alias CaptainFact.Flagger
  alias CaptainFact.Repo
  alias CaptainFact.Web.{User, Comment, Flag, Video, Statement}

  setup do
    Repo.delete_all(Flag)
    :ok
  end

  setup_all do
    Repo.delete_all(Flag)
    Repo.delete_all(User)
    target_user = Repo.insert! Map.merge(gen_user(0), %{reputation: 10000})
    comment = gen_comment(target_user)
    source_users = for user_num <- 1..Flagger.comments_nb_flags_to_ban do
      Repo.insert! Map.merge(gen_user(user_num), %{reputation: 10000})
    end
    {:ok, [source_users: source_users, target_user: target_user, comment: comment]}
  end

  test "flags get inserted in DB and user looses reputation", context do
    source = List.first(context[:source_users])
    comment = context[:comment]

    Flagger.flag!(comment, 1, source.id, false)
    assert Flagger.get_nb_flags(comment) == 1
    assert Repo.get!(User, context[:target_user].id).reputation < context[:target_user].reputation
  end

  test "comment banned after x flags and user looses reputation", context do
    comment = context[:comment]
    target = context[:target_user]

    for source <- context[:source_users] do
      Flagger.flag!(comment, 1, source.id, false)
    end
    assert Repo.get(Comment, comment.id).is_banned == true
    assert Repo.get!(User, target.id).reputation < target.reputation
  end

  defp gen_user(seed) do
    %User{
      name: "Jouje BigBrother",
      username: "User #{seed}",
      email: Faker.Internet.email,
      encrypted_password: "@StrongP4ssword!"
    }
  end

  defp gen_comment(user) do
    %Video{}
    |> Video.changeset(%{url: random_youtube_url(), title: "Test Video"})
    |> Repo.insert!()
    |> Ecto.build_assoc(:statements)
    |> Statement.changeset(%{text: "Statement text content. Foo Bar !", time: 42})
    |> Repo.insert!()
    |> Ecto.build_assoc(:comments)
    |> Map.put(:user_id, user.id)
    |> Comment.changeset(%{text: "Hello World !"})
    |> Repo.insert!()
  end

  defp random_youtube_url() do
    "https://www.youtube.com/watch?v=" <> (
      :crypto.strong_rand_bytes(11)
      |> Base.url_encode64
      |> binary_part(0, 11)
    )
  end
end

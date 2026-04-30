defmodule DB.Seeds do
  @moduledoc false

  import Ecto.Query, only: [from: 2]

  alias DB.Repo
  alias DB.Schema.{Statement, User, Video}

  @cypress_youtube_id "dQw4w9WgXcQ"
  @cypress_video_url "https://www.youtube.com/watch?v=#{@cypress_youtube_id}"

  @doc """
  Inserts dev-only defaults: a YouTube video used by Cypress (`/videos/Jzqg`), one
  statement (so the comment form can open), and the admin user.

  Idempotent: safe to run multiple times. The Cypress video must be inserted
  before the admin user so the video keeps `id == 1` and `hash_id == "Jzqg"`.
  """
  def seed_dev_data(repo \\ Repo) do
    env = Application.get_env(:db, :env)

    if env != :dev and env != :test do
      Logger.warning("API is running in non-dev mode. Skipping dev seeds.")
      :ok
    else
      seed_cypress_video_and_statement(repo)
      seed_dev_admin_user(repo)
    end

    :ok
  end

  defp seed_cypress_video_and_statement(repo) do
    case repo.get_by(Video, youtube_id: @cypress_youtube_id) do
      %Video{} = existing ->
        ensure_seed_statement(repo, existing.id)

      nil ->
        {:ok, video} =
          %Video{unlisted: false, is_partner: false}
          |> Video.changeset(%{
            url: @cypress_video_url,
            title: "Cypress seed video for e2e tests",
            language: "en"
          })
          |> repo.insert()

        video =
          video
          |> Video.changeset_generate_hash_id()
          |> repo.update!()

        ensure_seed_statement(repo, video.id)
    end
  end

  defp ensure_seed_statement(repo, video_id) do
    already? =
      repo.exists?(
        from(s in Statement,
          where: s.video_id == ^video_id
        )
      )

    unless already? do
      %Statement{}
      |> Statement.changeset(%{
        text: "Seed statement for Cypress comment tests.",
        time: 30,
        video_id: video_id
      })
      |> repo.insert!()
    end
  end

  defp seed_dev_admin_user(repo) do
    if repo.get_by(User, email: "admin@captainfact.io") do
      :ok
    else
      admin =
        User.registration_changeset(%User{reputation: 4200, username: "Captain"}, %{
          email: "admin@captainfact.io",
          password: "password"
        })

      repo.insert!(admin)
    end
  end

  @doc false
  def cypress_youtube_id, do: @cypress_youtube_id
end

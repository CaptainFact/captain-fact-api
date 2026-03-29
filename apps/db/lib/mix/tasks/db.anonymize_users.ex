defmodule Mix.Tasks.Db.AnonymizeUsers do
  @moduledoc """
  Replaces user emails, names, usernames, and related fields with fake data.

  Skips `users.id == 1` (typically the seeded admin). Intended for local dev after
  restoring a production dump.

  ## Usage

      mix db.anonymize_users

  Runs only when `MIX_ENV=dev`.
  """
  use Mix.Task

  @shortdoc "Anonymize user PII using Faker (skips user id=1)"

  @requirements ["app.start"]

  def run(_args) do
    if Mix.env() != :dev do
      Mix.raise("db.anonymize_users only runs in MIX_ENV=dev")
    end

    {:ok, _} = Application.ensure_all_started(:crypto)
    {:ok, _} = Application.ensure_all_started(:faker)
    Faker.start()

    alias DB.Repo
    alias DB.Schema.User
    alias DB.Utils.TokenGenerator

    import Ecto.Query

    password_hash = Bcrypt.hash_pwd_salt("password")

    ids =
      User
      |> select([u], u.id)
      |> Repo.all()

    Mix.shell().info("Anonymizing #{length(ids)} users (skipping id=1)...")

    Enum.each(ids, fn user_id ->
      user = Repo.get!(User, user_id)

      attrs = %{
        email: anonymized_email(user_id),
        username: anonymized_username(user_id),
        name: anonymized_name(),
        encrypted_password: password_hash,
        fb_user_id: nil,
        newsletter_subscription_token: TokenGenerator.generate(32),
        email_confirmation_token: nil,
        email_confirmed: false,
        picture_url: nil
      }

      case user |> Ecto.Changeset.change(attrs) |> Repo.update() do
        {:ok, _} -> :ok
        {:error, changeset} -> Mix.shell().error("user #{user_id}: #{inspect(changeset.errors)}")
      end
    end)

    # Admin user
    Repo.get!(User, 1)
    |> Ecto.Changeset.change(%{
      email: "admin@captainfact.io"
    })
    |> Repo.update()

    Mix.shell().info("Done.")
  end

  defp anonymized_email(id), do: "anonymized+#{id}@example.com"

  defp anonymized_username(id) do
    hex =
      :crypto.hash(:md5, "anon#{id}")
      |> Base.encode16(case: :lower)
      |> String.slice(0, 10)

    "anon_" <> hex
  end

  defp anonymized_name do
    raw =
      [Faker.Person.first_name(), Faker.Person.last_name()]
      |> Enum.join(" ")
      |> String.replace(~r/[0-9!*();:@&=+$,\/?#\[\].'\\]/u, "")
      |> String.replace(~r/\s+/, " ")
      |> String.trim()
      |> String.slice(0, 20)

    if String.length(raw) < 2, do: "Anonymous", else: raw
  end
end

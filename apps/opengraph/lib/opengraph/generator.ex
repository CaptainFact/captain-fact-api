defmodule Opengraph.Generator do
  alias DB.Schema.User

  require EEx

  @moduledoc """
  This module gather functions to generate an xml_builder tree based on
  """

  @template_path fn ->
    # In case of a non umbrella deployment
    if Mix.Project.umbrella?() do
      "./apps/opengraph"
    else
      "."
    end
    |> (fn root ->
          Path.join(root, "lib/opengraph/template.html.eex")
        end).()
  end

  EEx.function_from_file(
    :defp,
    :do_render,
    @template_path.(),
    [:description, :image, :title, :url],
    engine: Phoenix.HTML.Engine
  )

  defp render(%{
         description: description,
         image: image,
         title: title,
         url: url
       }) do
    do_render(description, image, title, url)
    |> Phoenix.HTML.safe_to_string()
  end

  # --- User ----

  @doc """
  render open graph metadata for given user
  """
  def render_user(user = %User{}, path) do
    encoded_url =
      "www.captainfact.io#{path}"
      |> URI.encode()

    escaped_username = Plug.HTML.html_escape(user.username)

    render(%{
      title: "le profil de : #{escaped_username} sur Captain Fact",
      url: encoded_url,
      description: "Découvrez le profil de #{escaped_username} sur Captain Fact",
      image: DB.Type.UserPicture.url({user.picture_url, user}, :thumb)
    })
  end

  # ---- Videos ----

  @doc """
  generate open graph tags for the videos index route
  """
  def render_videos_list(path) do
    render(%{
      title: "Les vidéos sourcées et vérifiées sur Captain Fact",
      url: "www.captainfact.io#{path}",
      description:
        "Découvrez diverses vidéos sourcées et vérifiées par la communauté Captain Fact",
      image: "captainfact.io/assets/img/logo.png"
    })
  end

  @doc """
  generate open graph tags for the given video
  """
  def render_video(video = %DB.Schema.Video{}, path) do
    %{
      title: "Vérification complète de : #{video.title}",
      url: "www.captainfact.io#{path}",
      description: "#{video.title} vérifiée citation par citation par la communauté Captain Fact",
      image: CaptainFact.Videos.image_url(video)
    }
    |> render
  end

  # ---- Speakers ----

  @doc """
  render open graph tags for the given speaker
  """
  def render_speaker(speaker = %DB.Schema.Speaker{}, path) do
    %{
      title: speaker.full_name,
      description: "Les interventions de #{speaker.full_name} sur Captain Fact",
      url: "www.captainfact.io#{path}",
      image: speaker.image_url
    }
    |> render
  end
end

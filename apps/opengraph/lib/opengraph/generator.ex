defmodule Opengraph.Generator do
  alias DB.Schema.User

  require EEx

  @moduledoc """
  This module gather functions to generate an xml_builder tree based on
  """

  @template_path fn () ->
    # In case of a non umbrella deployment
    if Mix.Project.umbrella? do
      "./apps/opengraph"
    else
      "."
    end
    |> fn root ->
        Path.join(root, "lib/opengraph/template.html.eex")
    end.()
  end

  EEx.function_from_file :defp, :do_render, @template_path.(), [:description, :image, :title,  :url], engine: Phoenix.HTML.Engine

  defp render(%{
    description: description,
    image: image,
    title: title,
    url: url
    })
  do
    do_render(description, image, title, url)
    |> Phoenix.HTML.safe_to_string
  end

  # --- User ----

  @doc """
  render open graph metadata for given user
  """
  def render_user(user = %User{}) do
    encoded_url =
    "www.captainfact.io/u/#{user.username}"
    |> URI.encode()

    escaped_username = Plug.HTML.html_escape(user.username)

    render(
      %{
        title: "#{escaped_username}'s profile on Captain Fact",
        url: encoded_url,
        description: "discover #{escaped_username}'s profile on Captain Fact",
        image: DB.Type.UserPicture.url({user.picture_url, user}, :thumb)
      }
    )
  end

  # ---- Videos ----

  @doc """
  generate open graph tags for the videos index route
  """
  def render_videos_list() do
    render(%{
      title: "Every videos crowd sourced and fact checked on Captain Fact",
      url: "www.captainfact.io/videos",
      description: "Discover the work of Captain Fact's community on diverse videos",
      image: "captainfact.io/assets/img/logo.png"
    })
  end

  @doc """
  generate open graph tags for the given video
  """
  def render_video(video) do
    %{
      title: "Vérification complète de : #{video.title}",
      url: "www.captainfact.io#{DB.Type.VideoHashId.encode(video.id)}",
      description: "#{video.title} vérifiée citation par citation par la communauté Captain Fact",
      image: CaptainFact.Videos.image_url(video)
    }
    |> render
  end

end

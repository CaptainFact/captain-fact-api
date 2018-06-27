defmodule Opengraph.Generator do
  alias DB.Schema.User
  alias Kaur.Result

  @moduledoc """
  This module gather functions to generate an xml_builder tree based on
  """

  def generate_xml(xml_tree) do
    XmlBuilder.doc(xml_tree)
  end

  def generate_html(xml_tree) do
    [{:html, nil, [{:head, nil, xml_tree}]}]
    |> XmlBuilder.doc()
  end

  @doc """
  encode property and content into a xml meta tag

  Protocol String.Chars must be implemented on content type

  ## Examples
    # you can encode basic scalar types (strings, number, booleans and atoms)
    iex> alias Opengraph.Generator
    iex> Generator.generate_tag("og:title", "a magnificent title")
    {
      :ok,
      {
        :meta,
        %{content: "a magnificent title", property: "og:title"},
        nil
      }
    }

    # you can encode lists
    iex> alias Opengraph.Generator
    iex> Generator.generate_tag("og:image", ["imageversion1.jpg", "imageversion2.jpg"])
    {
      :ok,
            [
        {
          :meta,
          %{content: "imageversion1.jpg", property: "og:image"},
          nil
        },
        {
          :meta,
          %{content: "imageversion2.jpg", property: "og:image"},
          nil
        }
      ]
    }

    # you can encode maps
    iex> alias Opengraph.Generator
    iex> Generator.generate_tag("og", %{title: "a magnificent title", description: "a magnificent content"})
    {
      :ok,
            [
        {
          :meta,
               %{content: "a magnificent content", property: "og:description"},
          nil
        },
        {
          :meta,
          %{content: "a magnificent title", property: "og:title"},
          nil
        }
      ]
    }
  """
  @spec generate_tag(binary, any) :: Result.result_tuple()
  def generate_tag(property, content)
      when is_list(content),
      do: do_encode_list_content(property, content)

  def generate_tag(property, content)
      when is_map(content),
      do: do_encode_map_content(property, content)

  def generate_tag(property, content), do: do_encode_basic_content(property, content)

  defp do_encode_basic_content(property, content) do
    try do
      {:meta, %{property: property, content: content}, nil}
      |> Result.ok()
    rescue
      _ in Protocol.UndefinedError ->
        {:error, "data impossible to encode, may be a problem with content type"}
    end
  end

  defp do_encode_list_content(property, content) do
    # content is a list containing every values for the same field
    content
    # encode a tag for every value
    |> Enum.map(&generate_tag(property, &1))
    # find error tags
    |> Result.sequence()
  end

  defp do_encode_map_content(property, content) do
    # content is a map containing different tags to encode
    content
    |> Enum.map(fn {k, v} ->
      # concat every keys to the given property
      generate_tag("#{property}:#{k}", v)
    end)
    # find error tags
    |> Result.sequence()
  end

  # --- User ----

  @doc """
  generate an open graph tags for the given user

  ## Examples
      alias Opengraph.Generator
      user = %DB.Schema.User{username: "captain", picture_url: "picture.jpg", id: 1}
      Generator.user_tags(user)
  """
  @spec user_tags(%User{}) :: binary
  def user_tags(user = %User{}) do
    # TODO : Dynamic urls
    encoded_url =
      "www.captainfact.io/u/#{user.username}"
      |> URI.encode()

    escaped_username = Plug.HTML.html_escape(user.username)

    %{
      title: "#{escaped_username}'s profile on Captain Fact",
      url: encoded_url,
      description: "discover #{escaped_username}'s profile on Captain Fact",
      image: DB.Type.UserPicture.url({user.picture_url, user}, :thumb)
    }
    |> (fn content -> generate_tag(:og, content) end).()
  end
end

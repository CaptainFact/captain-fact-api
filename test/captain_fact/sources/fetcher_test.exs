defmodule CaptainFact.Sources.FetcherTest do
  use CaptainFact.DataCase

  alias CaptainFact.Sources.Fetcher

  @valid_attributes %{
    language: "fr", # TODO remplace by locale
    title: "The article of the year",
    site_name: "Best site ever !",
    url: "/test"
  }

  test "fetches info from the page" do
    # Start web server providing a page with giver metadata
    {:ok, @valid_attributes} =
      serve(@valid_attributes.url, 200, @valid_attributes)
      |> endpoint_url(@valid_attributes.url)
      |> Fetcher.fetch_source_metadata()
  end

  test "return error if status is not 2xx" do
    # Error 404
    {:error, :not_found} =
      serve(@valid_attributes.url, 404, @valid_attributes)
      |> endpoint_url(@valid_attributes.url)
      |> Fetcher.fetch_source_metadata()

    # Random error between 300 and 600
    {:error, _} =
      serve(@valid_attributes.url, Enum.random([301, 302, 400, 500]), @valid_attributes)
      |> endpoint_url(@valid_attributes.url)
      |> Fetcher.fetch_source_metadata()
  end

  test "some arguments may be missing" do
    deleted_keys = Enum.take_random(Map.keys(@valid_attributes), Enum.random(1..4))
    attrs = Map.drop(@valid_attributes, deleted_keys)

    {:ok, response} =
      serve(@valid_attributes.url, 200, attrs)
      |> endpoint_url(@valid_attributes.url)
      |> Fetcher.fetch_source_metadata()

    assert response == attrs
  end

  defp serve(url, response_status, meta_attributes) do
    bypass = Bypass.open
    Bypass.expect_once bypass, "GET", url, fn conn ->
      Plug.Conn.resp(conn, response_status, generate_page(meta_attributes))
    end
    bypass
  end

  defp endpoint_url(bypass, url),
    do: "http://localhost:#{bypass.port}#{url}"

  defp generate_page(attrs) do
    """
    <html prefix="og: http://ogp.me/ns#" #{lang_attribute(attrs)}>
    <head>
    #{Enum.map(attrs, &meta_anchor/1)}
    </head>
    <body></body>
    </html>
    """
  end

  defp lang_attribute(%{language: locale}), do: "lang=\"#{locale}\""
  defp lang_attribute(_), do: ""

  defp meta_anchor({name, value}), do: """
    <meta property="og:#{name}" content="#{value}" />
  """
end
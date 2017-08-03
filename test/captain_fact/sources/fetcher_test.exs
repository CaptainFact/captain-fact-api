defmodule CaptainFact.Sources.FetcherTest do
  use CaptainFact.DataCase

  import CaptainFact.Support.MetaPage
  alias CaptainFact.Sources.Fetcher


  @valid_attributes %{
    language: "fr", # TODO remplace by locale
    title: "The article of the year",
    site_name: "Best site ever !",
    url: "/test"
  }


  test "fetches info from the page" do
    # Start web server providing a page with giver metadata
    bypass = serve(@valid_attributes.url, 200, @valid_attributes)
    url = endpoint_url(bypass, @valid_attributes.url)

    Fetcher.fetch_source_metadata(url, fn {:ok, response} ->
      assert response == put_real_url(@valid_attributes, bypass)
    end)
    wait_fetcher()
  end

  test "return error if status is not 2xx" do
    # Error 404
    serve(@valid_attributes.url, 404, @valid_attributes)
    |> endpoint_url(@valid_attributes.url)
    |> Fetcher.fetch_source_metadata(fn response ->
         assert response == {:error, :not_found}
       end)

    # Random error between 300 and 600
    serve(@valid_attributes.url, Enum.random([301, 302, 400, 500]), @valid_attributes)
    |> endpoint_url(@valid_attributes.url)
    |> Fetcher.fetch_source_metadata(fn {:error, _} ->
         :ok
       end)
    wait_fetcher()
  end

  test "some arguments may be missing" do
    deleted_keys = Enum.take_random(Map.keys(@valid_attributes), Enum.random(1..4))
    attrs = Map.drop(@valid_attributes, deleted_keys)

    bypass = serve(@valid_attributes.url, 200, attrs)
    url = endpoint_url(bypass, @valid_attributes.url)

    Fetcher.fetch_source_metadata(url, fn response ->
      assert response == {:ok, put_real_url(attrs, bypass)}
    end)
    wait_fetcher()
  end

  defp put_real_url(attrs, bypass) do
     if Map.has_key?(attrs, :url),
       do: Map.put(attrs, :url, endpoint_url(bypass, attrs.url)),
       else: attrs
  end

  defp wait_fetcher() do
    case MapSet.size(Fetcher.get_queue()) do
      0 -> :ok
      _ ->
        :timer.sleep(50)
        wait_fetcher()
    end
  end

#    test "don't try to fetch if url is invalid"
#    test "don't crash if callback crashes"
end
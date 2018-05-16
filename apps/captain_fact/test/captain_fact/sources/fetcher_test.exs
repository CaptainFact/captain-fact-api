defmodule CaptainFact.Sources.FetcherTest do
  use CaptainFact.DataCase

  import ExUnit.CaptureLog
  import CaptainFact.Support.MetaPage
  alias CaptainFact.Sources.Fetcher
  alias DB.Utils.TokenGenerator


  @valid_attributes %{
    language: "fr",
    title: "The article of the year",
    site_name: "Best site ever !",
    url: "/test"
  }


  test "fetches info from the page" do
    # Start web server providing a page with giver metadata
    bypass = serve(@valid_attributes.url, 200, @valid_attributes)
    url = endpoint_url(bypass, @valid_attributes.url)

    Fetcher.fetch_source_metadata(url, fn response ->
      assert response.title == @valid_attributes.title
      assert response.site_name == @valid_attributes.site_name
      assert response.language == @valid_attributes.language
      assert response.og_url == endpoint_url(bypass, @valid_attributes.url)
    end)
    wait_fetcher()
  end

  test "return error if status is not 2xx" do
    # Error 404
    @valid_attributes.url
    |> serve(404, @valid_attributes)
    |> endpoint_url(@valid_attributes.url)
    |> Fetcher.fetch_source_metadata(fn response ->
         assert response == {:error, :not_found}
       end)

    # Random error between 300 and 600
    @valid_attributes.url
    |> serve(Enum.random([301, 302, 400, 500]), @valid_attributes)
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
      assert response[:title] == attrs[:title]
      assert response[:site_name] == attrs[:site_name]
      assert response[:language] == attrs[:language]
      assert response[:og_url] == endpoint_url(bypass, attrs[:url])
    end)
    wait_fetcher()
  end

  test "Fetch everything even if some fails or crash" do
    # Init bypass server with 25 valid addresses, 25 invalid
    nb_urls = 50
    bypass = Bypass.open
    valid_urls = Enum.take(Stream.repeatedly(&gen_url/0), div(nb_urls, 3))
    invalid_urls = Enum.take(Stream.repeatedly(&gen_url/0), div(nb_urls, 3))
    crashing = Enum.take(Stream.repeatedly(&gen_url/0), div(nb_urls, 3))
    all_urls =
      [valid_urls, invalid_urls, crashing]
      |> List.zip()
      |> Stream.flat_map(fn {good, bad, crashing} -> [good, bad, crashing] end)

    for url <- valid_urls ++ crashing, do:
      Bypass.expect(bypass, "GET", url, plug_response(200, @valid_attributes))
    for url <- invalid_urls, do:
      Bypass.expect(bypass, "GET", url, plug_response(500, @valid_attributes))

    # Create a call counter to test how many time it succeed
    calls_counter_name = :test_fetch_calls_counter
    Agent.start_link(fn -> 0 end, name: calls_counter_name)
    increment_call = fn _ ->
      :timer.sleep(Enum.random(1..50))
      Agent.update(calls_counter_name, &(&1 + 1))
    end

    # Call fetcher and increment call counter
    log = capture_log(fn ->
      for url <- all_urls do
        if Enum.any?(crashing, &(&1 == url)) do
          Fetcher.fetch_source_metadata(endpoint_url(bypass, url), fn _ -> raise "RAISE_TEST" end)
        else
          Fetcher.fetch_source_metadata(endpoint_url(bypass, url), increment_call)
        end
      end
      wait_fetcher()
    end)
    assert Enum.count(Regex.scan(~r/RAISE_TEST/m, log)) === Enum.count(crashing)
    assert Agent.get(calls_counter_name, &(&1)) == Enum.count(valid_urls)
  end

  defp gen_url(), do: "/#{TokenGenerator.generate(8)}"

  defp wait_fetcher() do
    case MapSet.size(Fetcher.get_queue()) do
      0 -> :ok
      _ ->
        :timer.sleep(50)
        wait_fetcher()
    end
  end
end
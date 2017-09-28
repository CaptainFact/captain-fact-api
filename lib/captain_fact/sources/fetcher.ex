defmodule CaptainFact.Sources.Fetcher do

  require Logger
  alias CaptainFact.Sources.Fetcher


  @request_timeout 15_000
  @max_connections 4

  def link_checker_name, do: :sources_fetcher_checker
  def pool_name, do: :sources_fetcher_pool

  # ---- Public API ----

  def start_link() do
    import Supervisor.Spec
    Supervisor.start_link([
      :hackney_pool.child_spec(pool_name(), [
        timeout: @request_timeout,
        max_connections: @max_connections
      ]),
      worker(CaptainFact.Sources.Fetcher.LinkChecker, [])
    ], strategy: :one_for_all, name: __MODULE__)
  end

  @doc """
  Fetch given url infos and call callback with {:ok || :error, result}
  """
  def fetch_source_metadata(url, callback) do
    case Fetcher.LinkChecker.reserve_url(url) do
      :error -> :error # Already started, it's ok
      :ok ->
        Task.start(fn ->
          try do
            fetch(url, callback)
          rescue
            e -> Logger.error("Fetch metadata for #{url} crashed - #{inspect(e)}")
          after
            Fetcher.LinkChecker.free_url(url)
          end
        end)
    end
  end

  def get_queue, do: Fetcher.LinkChecker.get_queue()

  defp fetch(url, callback) do
    case do_fetch_source_metadata(url) do
      {:error, _} -> :error
      {:ok, result} -> callback.(result)
    end
  end

  defp do_fetch_source_metadata(url) do
    case HTTPoison.get(url, [], [follow_redirect: true, max_redirect: 5, hackney: [pool: pool_name()]]) do
      {:ok, %HTTPoison.Response{status_code: 200, body: body}} ->
        {:ok, source_params_from_tree(Floki.parse(body))}
      {:ok, %HTTPoison.Response{status_code: 404}} ->
        {:error, :not_found}
      {:ok, %HTTPoison.Response{status_code: _}} ->
        {:error, :unknown}
      {:error, %HTTPoison.Error{reason: reason}} ->
        {:error, reason}
    end
  end

  defp source_params_from_tree(tree) do
    %{
      title: Floki.attribute(tree, "meta[property='og:title']", "content"),
      title_alt: Floki.attribute(tree, "meta[name='abstract']", "content"),
      language: Floki.attribute(tree, "html", "lang"),
      site_name: Floki.attribute(tree, "meta[property='og:site_name']", "content"),
      url: Floki.attribute(tree, "meta[property='og:url']", "content")
    }
    |> Enum.map(fn({key, values}) -> {key, List.first(values)} end) # Only first entry
    |> Enum.filter(fn({_, value}) -> value != nil end)
    |> select_best_title()
    |> Enum.map(fn(entry = {key, value}) ->
      if key in [:title, :site_name],
        do: {key, HtmlEntities.decode(value)},
        else: entry
      end)
    |> Enum.into(%{})
  end

  # Select the best title between meta abstract and og:title then truncate it if needed
  defp select_best_title(attrs) do
    cond do
      Keyword.has_key?(attrs, :title) ->
        Keyword.update!(attrs, :title, &format_title/1)
      Keyword.has_key?(attrs, :title_alt) ->
        attrs
        |> Keyword.put(:title, format_title(Keyword.get(attrs, :title_alt)))
        |> Keyword.delete(:title_alt)
      true -> attrs
    end
  end

  defp format_title(title) do
    if String.length(title) > 250 do
      String.slice(title, 0, 250) <> "..."
    else
      title
    end
  end

  # Link checker

  defmodule LinkChecker do
    @doc """
    Agent that record which links are currently fetched
    """
    def start_link() do
      Agent.start_link(fn -> MapSet.new end, name: Fetcher.link_checker_name())
    end

    def reserve_url(url) do
      Agent.get_and_update(Fetcher.link_checker_name(), fn state ->
        if MapSet.member?(state, url) do
          {:error, state}
        else
          {:ok, MapSet.put(state, url)}
        end
      end)
    end

    def free_url(url),
      do: Agent.cast(Fetcher.link_checker_name(), &MapSet.delete(&1, url))

    def get_queue,
      do: Agent.get(Fetcher.link_checker_name(), &(&1))
  end
end
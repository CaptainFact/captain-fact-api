defmodule CF.Sources.Fetcher do
  require Logger
  alias CF.Sources.Fetcher

  @request_timeout 15_000
  @max_connections 4

  def link_checker_name, do: :sources_fetcher_checker
  def pool_name, do: :sources_fetcher_pool

  # ---- Public API ----

  def start_link() do
    import Supervisor.Spec

    Supervisor.start_link(
      [
        :hackney_pool.child_spec(
          pool_name(),
          timeout: @request_timeout,
          max_connections: @max_connections
        ),
        worker(CF.Sources.Fetcher.LinkChecker, [])
      ],
      strategy: :one_for_all,
      name: __MODULE__
    )
  end

  @doc """
  Fetch given url infos and call callback with {:ok || :error, result}
  """
  def fetch_source_metadata(url, callback) do
    case Fetcher.LinkChecker.reserve_url(url) do
      :error ->
        # Already started, it's ok
        :error

      :ok ->
        Task.start(fn ->
          try do
            fetch(url, callback)
          rescue
            exception ->
              CF.Errors.report(exception, __STACKTRACE__)
          after
            Fetcher.LinkChecker.free_url(url)
          end
        end)
    end
  end

  def get_queue, do: Fetcher.LinkChecker.get_queue()

  @url_regex ~r/^https?:\/\/[-a-zA-Z0-9@:%._\+~#=]{2,256}\.[a-z]{2,6}\b([-a-zA-Z0-9@:%_\+.~#?&\/\/=]*)/

  defp fetch(url, callback) do
    without_domain = Regex.replace(@url_regex, url, "\\1")
    path = Regex.replace(~r/\?.+$/, without_domain, "")

    case do_fetch_source_metadata(url, MIME.from_path(path)) do
      {:error, _} -> :error
      {:ok, result} -> callback.(result)
    end
  end

  @fetchable_mime_types ~w(text/html application/octet-stream application/xhtml+xml application/vnd.ms-htmlhelp)

  defp do_fetch_source_metadata(url, mime_types) when mime_types in @fetchable_mime_types do
    case HTTPoison.get(
           url,
           [],
           follow_redirect: true,
           max_redirect: 5,
           hackney: [pool: pool_name()]
         ) do
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

  defp do_fetch_source_metadata(url, mime_type) do
    ext = Path.extname(url)
    title = Path.basename(url, ext)
    {:ok, %{file_mime_type: mime_type, title: title}}
  end

  defp source_params_from_tree(tree) do
    head = Floki.find(tree, "head")

    %{
      title: attribute(head, "meta[property='og:title']", "content"),
      title_alt: attribute(head, "meta[name='abstract']", "content"),
      title_alt2: Floki.text(Floki.find(head, "title")),
      language: attribute(tree, "html", "lang"),
      site_name: attribute(head, "meta[property='og:site_name']", "content"),
      og_url: attribute(head, "meta[property='og:url']", "content")
    }
    |> Enum.filter(fn {_, value} -> value != nil && value != "" end)
    |> select_best_title()
    |> Enum.map(fn entry = {key, value} ->
      if key in [:title, :site_name],
        do: {key, HtmlEntities.decode(value)},
        else: entry
    end)
    |> Enum.into(%{})
  end

  defp attribute(head, anchor, attribute),
    do: List.first(Floki.attribute(head, anchor, attribute))

  # Select the best title between meta abstract and og:title then truncate it if needed
  defp select_best_title(attrs) do
    cond do
      Keyword.has_key?(attrs, :title) -> attrs
      Keyword.has_key?(attrs, :title_alt) -> extract_alt_title(attrs, :title_alt)
      Keyword.has_key?(attrs, :title_alt2) -> extract_alt_title(attrs, :title_alt2)
      true -> attrs
    end
  end

  defp extract_alt_title(attrs, key) do
    attrs
    |> Keyword.put(:title, Keyword.get(attrs, key))
    |> Keyword.delete(key)
  end

  # Link checker

  defmodule LinkChecker do
    @doc """
    Agent that record which links are currently fetched
    """
    def start_link() do
      Agent.start_link(fn -> MapSet.new() end, name: Fetcher.link_checker_name())
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
      do: Agent.get(Fetcher.link_checker_name(), & &1)
  end
end

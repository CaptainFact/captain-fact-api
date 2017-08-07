defmodule CaptainFact.Support.MetaPage do
  @moduledoc """
  Tools to serve an html page containing given meta attributes using a bypass server
  """

  def serve(url, response_status, meta_attributes, opts \\ []) do
    only_once = Keyword.get(opts, :only_once, false)
    ignore_meta_url_correction = Keyword.get(opts, :ignore_meta_url_correction, false)

    bypass = Bypass.open
    meta_attributes =
      if not ignore_meta_url_correction and Map.has_key?(meta_attributes, :url),
      do: Map.put(meta_attributes, :url, endpoint_url(bypass, Map.get(meta_attributes, :url))),
      else: meta_attributes

    func = plug_response(response_status, meta_attributes)
    if only_once,
      do: Bypass.expect_once(bypass, "GET", url, func),
      else: Bypass.expect(bypass, "GET", url, func)
    bypass
  end

  def plug_response(response_status, meta_attributes),
    do: fn conn -> Plug.Conn.resp(conn, response_status, generate_page(meta_attributes)) end

  def endpoint_url(_, nil), do: nil
  def endpoint_url(bypass, url), do: "http://localhost:#{bypass.port}#{url}"

  def generate_page(attrs) do
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
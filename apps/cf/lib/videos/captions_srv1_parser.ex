defmodule CF.Videos.CaptionsSrv1Parser do
  @moduledoc """
  A captions parser for the srv1 format.
  """

  require Logger
  import SweetXml

  def parse_file(content) do
    content
    |> SweetXml.xpath(
      ~x"//transcript/text"l,
      text: ~x"./text()"s |> transform_by(&clean_text/1),
      start: ~x"./@start"s |> transform_by(&parse_float/1),
      duration: ~x"./@dur"os |> transform_by(&parse_float/1)
    )
    |> Enum.filter(fn %{text: text, start: start} ->
      # Filter out text in brackets, like "[Music]"
      start != nil and text != nil and text != "" and
        String.match?(text, ~r/^\[.*\]$/) == false
    end)
  end

  defp clean_text(text) do
    text
    |> String.replace("&amp;", "&")
    |> HtmlEntities.decode()
    |> String.trim()
  end

  defp parse_float(val) do
    case Float.parse(val) do
      {num, _} -> num
      _ -> nil
    end
  end
end

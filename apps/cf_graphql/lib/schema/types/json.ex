defmodule CF.Graphql.Schema.Types.JSON do
  @moduledoc """
  JSON scalar type for Absinthe
  """
  use Absinthe.Schema.Notation

  scalar :json, name: "JSON" do
    description("JSON scalar type")

    serialize(&encode/1)
    parse(&decode/1)
  end

  defp encode(value) when is_map(value) or is_list(value) do
    value
  end

  defp encode(value) do
    value
  end

  defp decode(%Absinthe.Blueprint.Input.String{value: value}) do
    case Jason.decode(value) do
      {:ok, result} -> {:ok, result}
      _ -> :error
    end
  end

  defp decode(%Absinthe.Blueprint.Input.Null{}) do
    {:ok, nil}
  end

  defp decode(_) do
    :error
  end
end

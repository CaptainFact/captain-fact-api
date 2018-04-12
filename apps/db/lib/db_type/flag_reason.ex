defmodule DB.Type.FlagReason do
  @behaviour Ecto.Type
  def type, do: :integer

  @reasons %{
    "bad_language"     => 1,
    "spam"             => 2,
    "irrelevant"       => 3,
    "not_constructive" => 4
  }
  @nb_reasons Enum.count(@reasons)

  defguard is_valid_identifier(identifier)
    when is_integer(identifier) and identifier >= 1 and identifier <= @nb_reasons

  # ---- Ecto.Type implementation ----

  # Flag type can be passed as a string
  def cast(str)
  when is_binary(str) do
    case Map.get(@reasons, str) do
      nil -> :error
      id -> {:ok, id}
    end
  end

  # Accept integers
  def cast(identifier) when is_valid_identifier(identifier) do
    {:ok, identifier}
  end
  def cast(_), do: :error

  # Load from DB - keep base integer
  def load(integer), do: {:ok, integer}

  # When dumping data to the database, we *expect* an integer
  # but any value could be inserted into the struct, so we need
  # guard against them.
  def dump(integer) when is_valid_identifier(integer) do
    {:ok, integer}
  end
  def dump(_) do
    :error
  end

  # ---- Custom functions ----

  def label(reason_id) when is_valid_identifier(reason_id) do
    @reasons
    |> Enum.find(fn {_, id} -> id == reason_id end)
    |> elem(0)
  end
end
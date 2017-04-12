defmodule CaptainFact.VideoHashId do
  defmodule InvalidVideoHashError do
    @moduledoc """
    Exception raised when hash is not valid
    """
    defexception plug_status: 404, message: "Not found", conn: nil, router: nil
  end

  @moduledoc """
  Convert a video integer id to hash
  """

  @name __MODULE__

  def start_link do
    Agent.start_link(
      fn -> Hashids.new(
        min_len: 4,
        alphabet: "123456789abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ",
        salt: "C4pt41nV1d€0"
      ) end, name: @name
    )
  end

  @doc """
  Encode a given id
  ## Examples
      iex> CaptainFact.VideoHashId.encode(42)
      "4VyJ"
  """
  @spec encode(Integer.t) :: String.t
  def encode(id) do
    Agent.get(@name, &Hashids.encode(&1, id))
  end

  @doc """
  Decode a given hash
  ## Examples
      iex> CaptainFact.VideoHashId.decode("JbOz")
      {:ok, 1337}
      iex> CaptainFact.VideoHashId.decode("€€€€€€€€€€€€€€€€€")
      {:error, :invalid_input_data}
  """
  @spec decode(String.t) :: Integer.t
  def decode(hash) do
    case do_decode(hash) do
      {:ok, [id]} -> {:ok, id}
      error -> error
    end
  end

  @doc """
  Decode a given hash. Raise if hash is invalid
  ## Examples
      iex> CaptainFact.VideoHashId.decode!("JbOz")
      1337
      iex> CaptainFact.VideoHashId.decode!("€€€")
      ** (CaptainFact.VideoHashId.InvalidVideoHashError) Not found
  """
  @spec decode!(String.t) :: Integer.t
  def decode!(hash) do
    case do_decode(hash) do
      {:ok, [id]} -> id
      error -> raise InvalidVideoHashError
    end
  end

  defp do_decode(hash), do: Agent.get(@name, &Hashids.decode(&1, hash))
end

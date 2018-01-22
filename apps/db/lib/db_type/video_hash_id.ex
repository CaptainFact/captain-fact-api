defmodule DB.Type.VideoHashId do
  @moduledoc """
  Convert a video integer id to hash
  """

  defmodule InvalidVideoHashError do
    @moduledoc """
    Exception throwed when hash is not valid
    """
    defexception plug_status: 404, message: "Not found", conn: nil, router: nil
  end

  @coder Hashids.new(
    min_len: 4,
    alphabet: "123456789abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ",
    salt: "C4pt41nV1d€0"
  )

  @doc """
  Encode a given id
  ## Examples
      iex> DB.Type.VideoHashId.encode(42)
      "4VyJ"
  """
  @spec encode(Integer.t) :: String.t
  def encode(id) do
    Hashids.encode(@coder, id)
  end

  @doc """
  Decode a given hash
  ## Examples
      iex> DB.Type.VideoHashId.decode("JbOz")
      {:ok, 1337}
      iex> DB.Type.VideoHashId.decode("€€€€€€€€€€€€€€€€€")
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
      iex> DB.Type.VideoHashId.decode!("JbOz")
      1337
      iex> catch_throw(DB.Type.VideoHashId.decode!("€€€"))
      DB.Type.VideoHashId.InvalidVideoHashError
  """
  @spec decode!(String.t) :: Integer.t
  def decode!(hash) do
    case do_decode(hash) do
      {:ok, [id]} -> id
      _error -> throw InvalidVideoHashError
    end
  end

  defp do_decode(hash),
    do: Hashids.decode(@coder, hash)
end

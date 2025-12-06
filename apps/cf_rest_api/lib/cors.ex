defmodule CF.RestApi.CORS do
  @spec check_origin(String.t()) :: boolean()
  def check_origin(origin) do
    case Application.get_env(:cf_rest_api, :cors_origins) do
      "*" ->
        true

      origins ->
        origin in origins
    end
  end

  @spec check_origin(Plug.Conn.t(), String.t()) :: boolean()
  def check_origin(_conn, origin), do: check_origin(origin)
end

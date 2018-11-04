defmodule CF.RestApi.CORS do
  @spec check_origin(String.t()) :: boolean()
  def check_origin(origin) do
    case Application.get_env(:cf, :cors_origins) do
      "*" ->
        true

      origins ->
        origin in origins
    end
  end
end

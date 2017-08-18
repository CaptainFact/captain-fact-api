defmodule CaptainFactWeb.CORS do
  def check_origin(origin) do
    origin in Application.get_env(:captain_fact, :cors_origins)
  end
end
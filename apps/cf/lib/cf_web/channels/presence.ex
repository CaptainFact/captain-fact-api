defmodule CF.Web.Presence do
  @moduledoc """
  Provides presence tracking to channels and processes.

  See the [`Phoenix.Presence`](http://hexdocs.pm/phoenix/Phoenix.Presence.html)
  docs for more details.
  """
  use Phoenix.Presence, otp_app: :cf, pubsub_server: CF.PubSub

  def fetch(_topic, entries) do
    %{
      "viewers" => %{"count" => count_presences(entries, "viewers")},
      "users" => %{"count" => count_presences(entries, "users")}
    }
  end

  defp count_presences(entries, key) do
    case get_in(entries, [key, :metas]) do
      nil -> 0
      metas -> length(metas)
    end
  end
end

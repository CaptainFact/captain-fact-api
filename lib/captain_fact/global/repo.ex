defmodule CaptainFact.Repo do
  use Ecto.Repo, otp_app: :captain_fact
  use Scrivener, page_size: 10
end

defmodule DB.Repo do
  use Ecto.Repo, otp_app: :db
  use Scrivener, page_size: 10
end

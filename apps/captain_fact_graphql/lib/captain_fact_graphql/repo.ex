defmodule CaptainFactGraphql.Repo do
  use Ecto.Repo, otp_app: :captain_fact_graphql

  @doc """
  Dynamically loads the repository url from the
  DATABASE_URL environment variable.
  """
  def init(_, opts) do
    {:ok, Keyword.put(opts, :url, System.get_env("DATABASE_URL"))}
  end
end

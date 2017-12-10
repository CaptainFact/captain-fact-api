defmodule CaptainFactWeb.Resolvers.StatementsResolver do
  alias CaptainFact.Repo


  def video(statement, _, _) do
    {:ok, Repo.preload(statement, :video).video}
  end
end
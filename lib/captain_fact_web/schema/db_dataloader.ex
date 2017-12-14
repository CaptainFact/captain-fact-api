defmodule CaptainFactWeb.DataloaderDB do
  import Ecto.Query
  alias CaptainFact.Repo

  def dataloader() do
    Dataloader.add_source(Dataloader.new, __MODULE__, data())
  end

  def data(), do: Dataloader.Ecto.new(Repo, query: &query/2)

  # Never return removed statements from statements queries
  def query(Statement = query, _), do: from(s in query, where: s.is_removed == false)
  def query(queryable, _), do: queryable
end
defmodule CaptainFact.VideoDebate.History do
  import Ecto.Query

  alias CaptainFact.Repo
  alias CaptainFact.Actions.UserAction


  def context_history(context) do
    UserAction
    |> preload(:user)
    |> where([a], a.context == ^context)
    |> Repo.all()
  end

  def statement_history(statement_id) do
    UserAction
    |> preload(:user)
    |> where([a], a.entity == ^UserAction.entity(:statement))
    |> where([a], a.entity_id == ^statement_id)
    |> Repo.all()
  end
end
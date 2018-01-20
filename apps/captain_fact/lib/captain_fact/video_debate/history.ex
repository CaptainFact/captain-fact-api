defmodule CaptainFact.VideoDebate.History do
  import Ecto.Query

  alias DB.Repo
  alias CaptainFact.Actions.UserAction

  @allowed_entities [
    UserAction.entity(:statement),
    UserAction.entity(:speaker),
    UserAction.entity(:video),
  ]


  def context_history(context) do
    UserAction
    |> preload(:user)
    |> where([a], a.context == ^context)
    |> where([a], a.entity in ^@allowed_entities)
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
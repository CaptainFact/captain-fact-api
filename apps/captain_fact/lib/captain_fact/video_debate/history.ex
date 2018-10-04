defmodule CaptainFact.VideoDebate.History do
  import Ecto.Query

  alias DB.Repo
  alias DB.Schema.UserAction

  @allowed_entities [
    UserAction.entity(:statement),
    UserAction.entity(:speaker),
    UserAction.entity(:video)
  ]

  def video_history(video_id) do
    UserAction
    |> preload(:user)
    |> where([a], a.video_id == ^video_id)
    |> where([a], a.entity in ^@allowed_entities)
    |> Repo.all()
  end

  def statement_history(statement_id) do
    UserAction
    |> preload(:user)
    |> where([a], a.entity == ^UserAction.entity(:statement))
    |> where([a], a.statement_id == ^statement_id)
    |> Repo.all()
  end
end

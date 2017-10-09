defmodule CaptainFact.VideoDebate.History do
  import Ecto.Query

  alias CaptainFact.Repo
  alias CaptainFact.Actions.UserAction


  def video_debate_history(video_id) do
    UserAction
    |> preload(:user)
    |> where([a], a.context == ^UserAction.video_debate_context(video_id))
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
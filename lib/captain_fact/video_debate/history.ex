defmodule CaptainFact.VideoDebate.History do
  import Ecto.Query

  alias CaptainFact.Repo
  alias CaptainFactWeb.VideoDebateAction


  def video_history(video_id) do
    VideoDebateAction
    |> VideoDebateAction.with_user
    |> where([a], a.video_id == ^video_id)
    |> Repo.all()
  end

  def statement_history(statement_id) do
    VideoDebateAction
    |> VideoDebateAction.with_user
    |> where([a], a.entity == "statement")
    |> where([a], a.entity_id == ^statement_id)
    |> Repo.all()
  end
end
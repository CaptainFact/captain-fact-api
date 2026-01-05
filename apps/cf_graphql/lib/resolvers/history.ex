defmodule CF.Graphql.Resolvers.History do
  @moduledoc """
  Resolvers for history-related queries
  """

  alias CF.VideoDebate.History

  def video_history_actions(_root, %{video_id: video_id}, _info) do
    {:ok, History.video_history(video_id)}
  end

  def statement_history_actions(_root, %{statement_id: statement_id}, _info) do
    {:ok, History.statement_history(statement_id)}
  end
end






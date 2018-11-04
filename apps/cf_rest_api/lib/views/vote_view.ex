defmodule CF.RestApi.VoteView do
  use CF.RestApi, :view

  def render("my_votes.json", %{votes: votes}) do
    render_many(votes, CF.RestApi.VoteView, "my_vote.json")
  end

  def render("my_vote.json", %{vote: vote}) do
    %{
      comment_id: vote.comment_id,
      value: vote.value
    }
  end
end

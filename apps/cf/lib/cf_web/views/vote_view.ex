defmodule CF.Web.VoteView do
  use CF.Web, :view

  def render("my_votes.json", %{votes: votes}) do
    render_many(votes, CF.Web.VoteView, "my_vote.json")
  end

  def render("my_vote.json", %{vote: vote}) do
    %{
      comment_id: vote.comment_id,
      value: vote.value
    }
  end
end

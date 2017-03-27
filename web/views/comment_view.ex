defmodule CaptainFact.CommentView do
  use CaptainFact.Web, :view

  alias CaptainFact.{CommentView, UserView}

  def render("show.json", %{comment: comment}) do
    render_one(comment, CommentView, "comment.json")
  end

  def render("index.json", %{comments: comments}) do
    render_many(comments, CommentView, "comment.json")
  end

  def render("comment.json", %{comment: comment}) do
    %{
      id: comment.id,
      user: UserView.render("show_public.json", %{user: comment.user}),
      statement_id: comment.statement_id,
      text: comment.text,
      approve: comment.approve,
      inserted_at: comment.inserted_at,
      score: comment.score || 0,
      source: render_source(comment.source_url, comment.source_title)
    }
  end

  defp render_source(nil, _), do: nil

  defp render_source(url, title) do
    %{url: url, title: title}
  end
end

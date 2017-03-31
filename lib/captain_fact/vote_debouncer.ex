defmodule CaptainFact.VoteDebouncer do
  @moduledoc """
  Debounce a channel votes to avoid sending more than 1 channel update each
  @update_delay ms
  """

  import Ecto.Query

  @name __MODULE__
  @update_delay 5000 # 5 seconds


  def start_link, do: Agent.start_link(fn -> %{} end, name: @name)

  # --- API ---

  @doc """
  Add a vote to the debouncer
  ## Examples
    iex> CaptainFact.VoteDebouncer.add_vote(%{comment_id: 1})
  """
  def add_vote(channel_topic, comment_id) do
    Agent.update(@name, &do_add_vote(&1, channel_topic, comment_id))
  end

  @doc "Ask VoteDebouncer to update the channel with changed votes"
  def update(channel_topic) do
    Agent.update(@name, &do_update(&1, channel_topic))
  end

  # --- Methods ---

  defp do_add_vote(state, channel_topic, comment_id) do
    state
    |> Map.put_new(channel_topic, %{comments: MapSet.new, update_planned: false})
    |> update_in([channel_topic, :comments], &(MapSet.put(&1, comment_id)))
    |> setup_update(channel_topic)
  end

  defp setup_update(state, channel_topic) do
    if state[channel_topic][:update_planned] do
      state
    else
      # Start Task
      Task.start_link(fn -> delay_update(channel_topic) end)
      # Update state
      put_in(state, [channel_topic, :update_planned], true)
    end
  end

  defp delay_update(channel_topic) do
    :timer.sleep(@update_delay)
    CaptainFact.VoteDebouncer.update(channel_topic)
  end

  defp do_update(state, channel_topic) do
    updated_comments = MapSet.to_list(state[channel_topic][:comments])
    scores = CaptainFact.Vote
    |> select([v], %{
        comment_id: v.comment_id,
        score: sum(v.value)
      })
    |> where([v], v.comment_id in ^updated_comments)
    |> group_by([v], v.comment_id)
    |> CaptainFact.Repo.all

    CaptainFact.Endpoint.broadcast(
      channel_topic,
      "update_comments_scores",
      %{comments_scores: scores}
    )
    Map.delete(state, channel_topic)
  end
end

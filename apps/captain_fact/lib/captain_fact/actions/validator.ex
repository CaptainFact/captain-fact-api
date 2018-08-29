defmodule CaptainFact.Actions.Validator do
  @moduledoc """
  `UserAction` format and especially `changes` key are subject
  to change accross time. This module ensure all actions are
  correctly formatted.
  """

  alias DB.Schema.UserAction

  @doc """
  Check all actions from DB.

  Returns a list of errors like [{action_id, "message"}, ...].
  """
  def check_all() do
    UserAction
    |> DB.Repo.all()
    |> Enum.map(&{&1.id, check_action(&1)})
    |> Enum.filter(&(!match?({_, :ok}, &1)))
  end

  @doc """
  Check a single action. Returns :ok if nothing's wrong or
  a binary with the error message otherwise.
  """
  def check_action(action = %UserAction{}) do
    # TODO
  end
end

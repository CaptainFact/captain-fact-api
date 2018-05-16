defmodule CaptainFact.Actions.ReputationChange do
  alias DB.Schema.UserAction

  @actions %{
    # Votes
    UserAction.type(:vote_up) => %{
      UserAction.entity(:comment) =>  {0, +2},
      UserAction.entity(:fact) =>     {0, +3},
    },
    UserAction.type(:revert_vote_up) => %{
      UserAction.entity(:comment) =>  {0, -2},
      UserAction.entity(:fact) =>     {0, -3},
    },
    UserAction.type(:vote_down) => %{
      UserAction.entity(:comment) =>  {-1, -2},
      UserAction.entity(:fact) =>     {-1, -3}
    },
    UserAction.type(:revert_vote_down) => %{
      UserAction.entity(:comment) =>  {+1 , +2},
      UserAction.entity(:fact) =>     {+1 , +3}
    },

    # Moderation - target user got its comment banned
    UserAction.type(:action_banned_bad_language) =>     {0, -25},
    UserAction.type(:action_banned_spam) =>             {0, -30},
    UserAction.type(:action_banned_irrelevant) =>       {0, -10},
    UserAction.type(:action_banned_not_constructive) => {0, -5},

    # Moderation - source user (who made the flag) has made a good or bad flag
    UserAction.type(:abused_flag) =>          {0, -5},
    UserAction.type(:confirmed_flag) =>       {0, +3},

    # Misc
    UserAction.type(:email_confirmed) => {0, +15},
  }
  @actions_types Map.keys(@actions)


  @doc"""
  Return a list of all actions types known by reputation change calculator.
  """
  def actions_types, do: @actions_types

  @doc"""
  Get a tuple with {self_reputation_change, target_reputation_change)
  for given action type / entity.
  """
  def for_action(%UserAction{type: type, entity: entity}) do
    case Map.get(@actions, type) do
      nil -> {0, 0}
      res when is_map(res) -> Map.get(res, entity) || {0, 0}
      res when is_tuple(res) -> res
    end
  end
  def for_action(type) when is_atom(type),
    do: for_action(UserAction.type(type))
  def for_action(type) when is_integer(type),
    do: Map.get(@actions, type) || {0, 0}
  def for_action(type, entity) when is_atom(type) and is_atom(entity),
    do: for_action(UserAction.type(type), UserAction.entity(entity))
  def for_action(type, entity) when is_integer(type) and is_integer(entity),
    do: get_in(@actions, [type, entity]) || {0, 0}

  @doc"""
  Get reputation change as an integer for admin action (email confirmed, abusive
  flag...etc)
  """
  def for_admin_action(type), do: elem(for_action(type), 1)
end
defmodule CaptainFact.Actions.Validator do
  @moduledoc """
  `UserAction` format and especially `changes` key are subject
  to change accross time. This module ensure all actions are
  correctly formatted.
  """

  use CaptainFact.Actions.ValidatorBase

  # Check entities keys based on entity type. Note that the first matching type
  # will be the only one executed of all `check_entity_wildcard`
  # so you can't define multiple matching clauses per type
  check_entity_wildcard(:video, ~w(video_id)a)
  check_entity_wildcard(:speaker, ~w(speaker_id)a)
  check_entity_wildcard(:statement, ~w(statement_id video_id)a)
  check_entity_wildcard(:comment, ~w(comment_id statement_id video_id)a, exclude: [:delete])

  # Same here, only the first pattern will match
  check_action_changes(:video, :add, required: ["url"])
  check_action_changes(:video, :update, whitelist: ~w(statements_time))
  check_action_changes(:speaker, :add, has_changes: false)
  check_action_changes(:speaker, :create, required: ["full_name"], whitelist: ["title"])
  check_action_changes(:speaker, :remove, has_changes: false)
  check_action_changes(:speaker, :delete, has_changes: false)
  check_action_changes(:speaker, :update, whitelist: ~w(title full_name wikidata_item_id picture))
  check_action_changes(:statement, :create, required: ["time", "text"], whitelist: ["speaker_id"])
  check_action_changes(:statement, :update, whitelist: ["speaker_id", "text", "time"])
  check_action_changes(:statement, :remove, has_changes: false)
  check_action_changes(:comment, :delete, has_changes: false)
  check_action_changes(:comment, :vote_up, has_changes: false)

  ignore_others_actions()
end

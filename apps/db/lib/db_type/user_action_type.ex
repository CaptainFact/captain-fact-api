import EctoEnum

defenum(
  DB.Type.UserActionType,
  # Common
  create: 1,
  remove: 2,
  update: 3,
  delete: 4,
  add: 5,
  restore: 6,
  approve: 7,
  flag: 8,
  # Voting stuff
  vote_up: 9,
  vote_down: 10,
  self_vote: 11,
  revert_vote_up: 12,
  revert_vote_down: 13,
  revert_self_vote: 14,
  # Bans - See DB.Type.FlagReason for labels
  action_banned_bad_language: 21,
  action_banned_spam: 22,
  action_banned_irrelevant: 23,
  action_banned_not_constructive: 24,
  # Special actions
  email_confirmed: 100,
  collective_moderation: 101,
  start_automatic_statements_extraction: 102,
  # Deprecated. Can safelly be re-used
  action_banned: 102,
  abused_flag: 103,
  confirmed_flag: 104,
  social_network_linked: 105
)

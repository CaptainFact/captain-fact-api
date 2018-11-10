defmodule CF.ModerationTest do
  use CF.DataCase
  #  import CF.TestUtils, only: [flag_comments: 2]
  doctest CF.Moderation

  # TODO can only give one feedback
  # TODO cannot give feedback on an action which is not reported
  # TODO Make sure user doesn't get and cannot give feedback on its own actions or actions he's targeted by
end

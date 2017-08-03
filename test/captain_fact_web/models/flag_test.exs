defmodule CaptainFact.FlagTest do
  use CaptainFact.DataCase, async: true

  alias CaptainFactWeb.Flag
  alias CaptainFact.Comments.Comment


  @valid_comment %Comment{id: 1, user_id: 42}
  @base_flag %Flag{source_user_id: 1}

  test "changeset with valid attributes" do
    changeset = Flag.changeset_comment(@base_flag, @valid_comment, %{reason: 1})
    assert changeset.valid?
  end

  test "reason cannot be anything" do
    changeset = Flag.changeset_comment(@base_flag, @valid_comment, %{reason: 0})
    refute changeset.valid?

    changeset = Flag.changeset_comment(@base_flag, @valid_comment, %{reason: 4})
    refute changeset.valid?
  end
end

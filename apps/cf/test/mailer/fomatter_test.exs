defmodule CF.Mailer.FormatterTest do
  use CF.DataCase

  test "format email address" do
    user = DB.Factory.build(:user)
    {appelation, email} = Bamboo.Formatter.format_email_address(user, [])
    assert email == user.email
    assert appelation =~ user.username
    assert appelation =~ user.name
  end
end

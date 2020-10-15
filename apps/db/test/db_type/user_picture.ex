defmodule DB.Type.UserPictureTest do
  use DB.DataCase, async: true
  doctest DB.Schema.User

  import DB.Factory, only: [insert: 1, insert: 2]
  alias DB.Schema.User

  test "defaults to gravatar" do
    user = insert(:user, picture_url: nil)
    email_md5 = :crypto.hash(:md5, user.email) |> Base.encode16(case: :lower)

    assert DB.Type.UserPicture.default_url(:thumb, user) ==
             "https://gravatar.com/avatar/#{email_md5}.jpg?size=94&d=robohash"
  end
end

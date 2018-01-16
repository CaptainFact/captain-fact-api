defmodule CaptainFactGraphql.Resolvers.Users do
  def picture_url(user, _, _) do
    {:ok, CaptainFact.Accounts.UserPicture.url({user.picture_url, user}, :thumb)}
  end

  def mini_picture_url(user, _, _) do
    {:ok, CaptainFact.Accounts.UserPicture.url({user.picture_url, user}, :mini_thumb)}
  end
end
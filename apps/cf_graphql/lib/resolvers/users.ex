defmodule CF.GraphQL.Resolvers.Users do
  def picture_url(user, _, _) do
    {:ok, DB.Type.UserPicture.url({user.picture_url, user}, :thumb)}
  end

  def mini_picture_url(user, _, _) do
    {:ok, DB.Type.UserPicture.url({user.picture_url, user}, :mini_thumb)}
  end
end

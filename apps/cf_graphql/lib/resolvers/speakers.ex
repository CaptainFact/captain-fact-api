defmodule CF.Graphql.Resolvers.Speakers do
  def picture(speaker, _, _) do
    {:ok, DB.Type.SpeakerPicture.full_url(speaker, :thumb)}
  end
end

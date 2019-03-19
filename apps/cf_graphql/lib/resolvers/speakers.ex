defmodule CF.Graphql.Resolvers.Speakers do
  def picture(speaker, _, _) do
    {:ok, DB.Type.SpeakerPicture.url({speaker.picture, speaker}, :thumb)}
  end
end

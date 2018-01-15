defmodule CaptainFactWeb.Resolvers.Speakers do
  def picture(speaker, _, _) do
    {:ok, CaptainFact.Speakers.Picture.url({speaker.picture, speaker}, :thumb)}
  end
end
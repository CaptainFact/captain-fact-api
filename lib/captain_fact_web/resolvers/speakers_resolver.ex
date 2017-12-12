defmodule CaptainFactWeb.Resolvers.SpeakersResolver do
  def picture(speaker, _, _) do
    {:ok, CaptainFact.Speakers.Picture.url({speaker.picture, speaker}, :thumb)}
  end

  def videos(speaker, _, _) do
    {:ok, CaptainFact.Repo.preload(speaker, :videos).videos}
  end
end
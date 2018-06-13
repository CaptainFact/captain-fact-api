defmodule Opengraph.Router do
  use Plug.Router

  get "/u/:username" do
    username = conn[:params]["username"]


  end

  # get "/videos" do
  #   VideoController.index(conn)
  # end

  # get "/videos/:video_id" do
  #   VideoController.get(conn)
  # end

  # get "/videos/:video_id/history" do
  #   VideoController.get_history(conn)
  # end

  # get "/s/:slug_or_id" do
  #   SpeakerController.get(conn)
  # end
end

defmodule CF.Jobs.DownloadCaptions do
  @behaviour CF.Jobs.Job

  require Logger
  import Ecto.Query

  alias DB.Repo
  alias DB.Schema.Video
  alias DB.Schema.VideoCaption
  alias DB.Schema.UsersActionsReport

  @name :download_captions
  @analyser_id UsersActionsReport.analyser_id(@name)

  # --- Client API ---

  def name, do: @name

  def start_link() do
    GenServer.start_link(__MODULE__, :ok, name: __MODULE__)
  end

  def init(args) do
    {:ok, args}
  end

  # 2 minutes
  @timeout 120_000
  def update() do
    GenServer.call(__MODULE__, :download_captions, @timeout)
  end

  # --- Server callbacks ---
  def handle_call(:download_captions, _from, _state) do
    get_videos()
    |> Enum.map(fn video ->
      Logger.info("Downloading captions for video #{video.id}")
      CF.Videos.download_captions(video)
    end)

    {:reply, :ok, :ok}
  end

  # Get all videos that need new captions. We fetch new captions:
  # - For any videos that doesn't have any captions yet
  # - For videos whose captions haven't been updated in the last 30 days
  defp get_videos() do
    Repo.all(
      from(v in Video,
        limit: 15,
        left_join: captions in VideoCaption,
        on: captions.video_id == v.id,
        where:
          is_nil(captions.id) or
            captions.updated_at < ^DateTime.add(DateTime.utc_now(), -30 * 24 * 60 * 60, :second),
        group_by: v.id,
        order_by: [desc: v.inserted_at]
      )
    )
  end
end

defmodule CF.Jobs.DownloadCaptions do
  @behaviour CF.Jobs.Job

  require Logger
  import Ecto.Query
  import ScoutApm.Tracing

  alias DB.Repo
  alias DB.Schema.UserAction
  alias DB.Schema.UsersActionsReport

  alias CF.Jobs.ReportManager

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

  # 1 minute
  @timeout 60_000
  def update() do
    GenServer.call(__MODULE__, :download_captions, @timeout)
  end

  # --- Server callbacks ---
  @transaction_opts [type: "background", name: "download_captions"]
  def handle_call(:download_captions, _from, _state) do
    get_videos()
    |> Enum.map(fn video ->
      Logger.info("Downloading captions for video #{video.id}")
      download_captions(video)
    end)

    {:reply, :ok, :ok}
  end

  # Get all videos that need new captions. We fetch new captions:
  # - For any videos that doesn't have any captions yet
  # - For videos whose captions haven't been updated in the last 30 days
  defp get_videos() do
    Repo.all(
      from(v in DB.Schema.Video,
        where: is_nil(v.captions_updated_at) or v.captions_updated_at < Date.add(Date.utc_today(), -30),
        preload: [:channel]
      )
    )
  end
end

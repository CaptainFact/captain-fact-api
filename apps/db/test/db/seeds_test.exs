defmodule DB.SeedsTest do
  use DB.DataCase, async: false

  alias DB.Schema.{Statement, User, Video}
  alias DB.Seeds
  alias DB.Type.VideoHashId

  @youtube_id "dQw4w9WgXcQ"

  test "seed_dev_data creates Cypress video with hash_id, statement, and admin" do
    assert :ok = Seeds.seed_dev_data()

    video = Repo.get_by!(Video, youtube_id: @youtube_id)
    assert video.hash_id == VideoHashId.encode(video.id)
    assert video.unlisted == false

    assert Repo.get_by!(Statement, video_id: video.id)

    assert Repo.get_by!(User, email: "admin@captainfact.io")
  end

  test "first inserted video on a fresh database gets hash Jzqg (Cypress /videos/Jzqg)" do
    # Sandbox rolls back rows but not PostgreSQL sequences, so other tests may have
    # advanced the videos id sequence; only the encode invariant is asserted above.
    # On a new dev DB, the seeded video is the first row in `videos` (id=1 → Jzqg).
    assert VideoHashId.encode(1) == "Jzqg"
  end
end

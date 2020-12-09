defmodule CF.SpeakersTest do
  use CF.DataCase
  alias CF.Speakers

  setup do
    DB.Repo.delete_all(DB.Schema.Speaker)
    :ok
  end

  @full_name "Frank Zappa"
  @slug "Frank-Zappa"
  @other_full_name "Frank Zappette"
  @other_slug "Frank-Zappette"

  describe "generate slug" do
    test "generates a slug from name" do
      speaker = insert(:speaker, slug: nil, full_name: @full_name)
      {:ok, updated_speaker} = Speakers.generate_slug(speaker)
      assert updated_speaker.slug == @slug
    end

    test "error if slug already exists" do
      speaker = insert(:speaker, slug: nil, full_name: @full_name)
      speaker_duplicate = insert(:speaker, slug: nil, full_name: @full_name)
      assert {:ok, _} = Speakers.generate_slug(speaker)
      assert {:error, %Ecto.Changeset{}} = Speakers.generate_slug(speaker_duplicate)
    end

    test "update slug if already filled" do
      speaker = insert(:speaker, slug: @slug, full_name: @other_full_name)
      assert {:ok, updated_speaker} = Speakers.generate_slug(speaker)
      assert updated_speaker.slug == @other_slug
    end
  end

  describe "generate all slugs" do
    test "generate slugs for speakers with nil slug" do
      speaker = insert(:speaker, slug: nil, full_name: @full_name)
      Speakers.generate_all_slugs()
      assert DB.Repo.get(DB.Schema.Speaker, speaker.id).slug == @slug
    end

    test "does't update existing slugs" do
      speaker = insert(:speaker, slug: @slug, full_name: @other_full_name)
      Speakers.generate_all_slugs()
      assert DB.Repo.get(DB.Schema.Speaker, speaker.id).slug == @slug
    end
  end

  describe "merge_speakers" do
    test "merges profiles and related data" do
      speaker1 = insert(:speaker, %{title: "speaker_1"})
      speaker2 = insert(:speaker, %{title: nil})
      speaker1_statements = insert_list(3, :statement, speaker: speaker1)
      speaker2_statements = insert_list(4, :statement, speaker: speaker2)
      speaker1_videos = insert_list(3, :video_speaker, speaker: speaker1)
      speaker2_videos = insert_list(4, :video_speaker, speaker: speaker2)
      speaker1_users = insert_list(3, :user, speaker: speaker1)
      speaker2_users = insert_list(4, :user, speaker: speaker2)

      {:ok, result} = Speakers.merge_speakers(speaker1, speaker2)

      assert result.speaker_from.id === speaker1.id
      assert result.speaker_into.id === speaker2.id

      # Profiles should be merged
      assert result.speaker_into.title == speaker1.title

      # Statements should be upddated
      assert elem(result.statements, 0) == 3

      assert DB.Repo.aggregate(
               from(s in DB.Schema.Statement, where: s.speaker_id == ^speaker2.id),
               :count,
               :id
             ) == 7

      # Videos should be updated
      assert elem(result.videos_speakers, 0) == 3

      assert DB.Repo.aggregate(
               from(s in DB.Schema.VideoSpeaker, where: s.speaker_id == ^speaker2.id),
               :count,
               :video_id
             ) == 7

      # Users should be upddated
      assert elem(result.users, 0) == 3

      assert DB.Repo.aggregate(
               from(s in DB.Schema.User, where: s.speaker_id == ^speaker2.id),
               :count,
               :id
             ) == 7

      # First speaker should be deleted
      assert DB.Repo.get(DB.Schema.Speaker, speaker1.id) == nil
    end
  end
end

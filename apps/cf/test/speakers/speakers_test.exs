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
end

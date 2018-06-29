defmodule Opengraph.GeneratorTest do
  use ExUnit.Case

  import DB.Factory

  alias Kaur.Result
  alias Opengraph.Generator

  doctest Opengraph.Generator

  describe "video_tags/1" do
    setup _context do
      [video: insert(:video)]
    end

    test "it is not currently implemented", context do
      video = context[:video]

      assert(Generator.video_tags(video)) == Result.error("Not implemented")
    end

    test "it returns {:ok, value} for a valid video", context do
      video = context[:video]

      assert {:ok, _} = Generator.video_tags(video)
    end
  end
end

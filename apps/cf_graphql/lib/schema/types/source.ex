defmodule CF.Graphql.Schema.Types.Source do
  @moduledoc """
  Representation of a `DB.Schema.Source` for Absinthe
  """

  use Absinthe.Schema.Notation
  use Absinthe.Ecto, repo: DB.Repo

  @desc "An URL pointing toward a source (article, video, pdf...)"
  object :source do
    @desc "Unique id of the source"
    field(:id, non_null(:id))
    @desc "URL of the source"
    field(:url, non_null(:string))
    @desc "Title of the page / article"
    field(:title, :string)
    @desc "Language of the page / article"
    field(:language, :string)
    @desc "Site name extracted from OpenGraph"
    field(:site_name, :string)
  end
end

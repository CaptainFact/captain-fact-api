defmodule CF.Graphql.Schema.Types.AppInfo do
  @moduledoc """
  App info representation. Contains version, status...etc
  """

  use Absinthe.Schema.Notation
  use Absinthe.Ecto, repo: DB.Repo

  @desc "Information about the application"
  object :app_info do
    @desc "Indicate if the application is running properly with a checkmark"
    field(:status, non_null(:string))
    @desc "Graphql API version"
    field(:version, non_null(:string))
    @desc "Version of the database app attached to this API"
    field(:db_version, non_null(:string))
  end
end

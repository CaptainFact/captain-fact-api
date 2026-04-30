defmodule CF.Graphql.Schema.Types.AppInfo do
  @moduledoc """
  App info representation. Contains version, status...etc
  """

  use Absinthe.Schema.Notation

  @desc "Information about the application"
  object :app_info do
    @desc "Indicate if the application is running properly with a checkmark"
    field(:status, non_null(:string))
    @desc "Graphql API version"
    field(:version, non_null(:string))
    @desc "Version of the database app attached to this API"
    field(:db_version, non_null(:string))
    @desc "Environment the application is running in"
    field(:env, non_null(:string))
    @desc "Host the application is running on"
    field(:host, non_null(:string))
    @desc "Mix environment the application is running in"
    field(:mix_env, non_null(:string))
  end
end

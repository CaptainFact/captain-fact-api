defmodule CF.Errors do
  @moduledoc """
  Module to report errors, currenctly plugged on Rollbar with important metadata
  added. It mostly mimics `Rollbax` API.
  """

  @type cf_error_params :: [
          user: DB.Schema.User.t(),
          custom: Map.t(),
          data: Map.t()
        ]

  @doc """
  Reports the given error.
  """
  @spec report(any(), [any()], cf_error_params()) :: :ok
  def report(value, stacktrace, params \\ []) do
    do_report(:error, value, stacktrace, params)
  end

  @doc """
  Reports the given throw.
  """
  @spec report_throw(any(), [any()], cf_error_params()) :: :ok
  def report_throw(value, stacktrace, params \\ []) do
    do_report(:throw, value, stacktrace, params)
  end

  @doc """
  Reports the given exit.
  """
  @spec report_exit(any(), [any()], cf_error_params()) :: :ok
  def report_exit(value, stacktrace, params \\ []) do
    do_report(:exit, value, stacktrace, params)
  end

  @spec do_report(:error | :exit | :throw, any(), [any()], cf_error_params()) :: :ok
  def do_report(type, value, stacktrace, params) do
    Rollbax.report(
      type,
      value,
      stacktrace,
      params[:custom] || %{},
      build_occurence_data(params)
    )
  end

  defp build_occurence_data(params) do
    default_occurrence_data()
    |> add_user(params[:user])
    |> Map.merge(params[:data] || %{})
  end

  defp default_occurrence_data() do
    %{
      "code_version" => CF.Application.version()
    }
  end

  defp add_user(base, nil),
    do: base

  defp add_user(base, %{id: id, username: username}),
    do: Map.merge(base, %{"person" => %{"id" => Integer.to_string(id), "username" => username}})

  defp add_user(base, %{id: id}),
    do: Map.merge(base, %{"person" => %{"id" => Integer.to_string(id)}})
end

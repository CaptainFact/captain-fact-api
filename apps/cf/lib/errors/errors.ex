defmodule CF.Errors do
  @moduledoc """
  Module to report errors
  """

  require Logger

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
  def do_report(type, value, stacktrace, _params) do
    # Any call to Sentry, Rollbar, etc. should be done here
    Logger.error("[ERROR][#{type}] #{inspect(value)} - #{inspect(stacktrace)}")
    :ok
  end
end

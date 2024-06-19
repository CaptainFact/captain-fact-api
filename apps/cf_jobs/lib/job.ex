defmodule CF.Jobs.Job do
  @moduledoc """
  Define the common behaviour between jobs.
  """

  @type t :: module

  use GenServer

  def init(args) do
    {:ok, args}
  end

  @doc """
  Get the Job name.
  """
  @callback name() :: atom()
end

defmodule CaptainFactJobs do
  @moduledoc """
  Regroup all background jobs for CaptainFact. For scheduling, please look
  at `captain_fact/config/config.exs` at `Quantum` section.
  """

  @doc """
  Run all jobs. This function is mostly useful in dev and test environments and
  is not meant to be used in business code; prefer scheduling tasks individually
  in Quantum configuration by calling the specific `update/0` functions.
  """
  def update_all() do
    CaptainFactJobs.Achievements.update()
    CaptainFactJobs.Flags.update()
    CaptainFactJobs.Moderation.update()
    CaptainFactJobs.Reputation.update()
    CaptainFactJobs.Votes.update()
  end
end
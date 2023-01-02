defmodule CF.Jobs.Scheduler do
  use Quantum, otp_app: :cf_jobs

  #  Scheduler (job runner) implementation. See `config/config.exs` to see the
  #  exact configuration with run intervals.
end

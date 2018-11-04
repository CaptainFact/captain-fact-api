defmodule CF.Scheduler do
  use Quantum.Scheduler, otp_app: :cf

  #  Scheduler (job runner) implementation. See `config/config.exs` to see the
  #  exact configuration with run intervals.
end

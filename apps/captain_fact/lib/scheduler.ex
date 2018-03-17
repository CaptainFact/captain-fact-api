defmodule CaptainFact.Scheduler do
  use Quantum.Scheduler, otp_app: :captain_fact

  #  Scheduler (job runner) implementation. See `config/config.exs` to see the
  #  exact configuration with run intervals.
end
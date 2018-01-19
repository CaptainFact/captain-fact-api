defmodule CaptainFactREST.FlagView do
  use CaptainFactREST, :view

  def render("my_flags.json", %{flags: flags}) do
    render_many(flags, CaptainFactREST.FlagView, "my_flag.json")
  end

  def render("my_flag.json", %{flag: flag}) do
    %{
      entity: flag.entity,
      entity_id: flag.entity_id
    }
  end
end
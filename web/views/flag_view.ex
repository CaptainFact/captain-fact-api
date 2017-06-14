defmodule CaptainFact.FlagView do
  use CaptainFact.Web, :view

  def render("my_flags.json", %{flags: flags}) do
    render_many(flags, CaptainFact.FlagView, "my_flag.json")
  end

  def render("my_flag.json", %{flag: flag}) do
    %{
      type: flag.type,
      entity_id: flag.entity_id
    }
  end
end
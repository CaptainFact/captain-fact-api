defmodule CaptainFact.ErrorViewTest do
  use CaptainFact.ConnCase, async: true

  # Bring render/3 and render_to_string/3 for testing custom views
  import Phoenix.View

  test "renders 404.json" do
    assert render_to_string(CaptainFact.ErrorView, "404.json", []) =~ "Not Found"
  end

  test "render 500.json" do
    assert render_to_string(CaptainFact.ErrorView, "500.json", []) =~
           "Server encountered an unexpected error. We're working on it !"
  end

  test "render any other" do
    assert render_to_string(CaptainFact.ErrorView, "505.json", []) =~
           "Server encountered an unexpected error. We're working on it !"
  end
end

defmodule CF.ErrorViewTest do
  use CF.RestApi.ConnCase

  # Bring render/3 and render_to_string/3 for testing custom views
  import Phoenix.View
  alias CF.RestApi.ErrorView
  alias CF.Accounts.UserPermissions.PermissionsError

  test "renders 401.json" do
    assert render_to_string(ErrorView, "401.json", []) =~ "unauthorized"
  end

  test "renders 403.json" do
    assert render_to_string(ErrorView, "403.json", []) =~ "forbidden"
  end

  test "renders 403.json with PermissionsError" do
    assert render_to_string(ErrorView, "403.json", %{reason: %PermissionsError{message: "xxx"}}) =~
             "xxx"
  end

  test "renders 404.json" do
    assert render_to_string(ErrorView, "404.json", []) =~ "not_found"
  end

  test "render any other" do
    assert render_to_string(ErrorView, "999.json", []) =~ "unexpected"
  end
end

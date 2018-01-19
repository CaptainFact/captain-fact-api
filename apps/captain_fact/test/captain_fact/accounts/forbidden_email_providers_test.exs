defmodule CaptainFact.Accounts.ForbiddenEmailProvidersTest do
  use ExUnit.Case, async: true
  # TODO [Refactor] Remove (external dependency)

  alias CaptainFact.Accounts.ForbiddenEmailProviders

  test "filters bad emails providers" do
    providers = ForbiddenEmailProviders.get_temporary_providers()
    assert ForbiddenEmailProviders.is_forbidden?("myemail@" <> Enum.random(providers))
  end

  test "example: filters jetable.org" do
    assert ForbiddenEmailProviders.is_forbidden?("test@jetable.org")
  end

  test "strictly compare domain" do
    providers = ForbiddenEmailProviders.get_temporary_providers()
    refute ForbiddenEmailProviders.is_forbidden?("myemail@not_temporary_" <> Enum.random(providers))
  end

  test "returns false when email has bad format (simple check, not full regex)" do
    assert ForbiddenEmailProviders.is_forbidden?("myemail@gmail.com@gmail.com")
  end
end
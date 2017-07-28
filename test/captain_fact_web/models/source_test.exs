defmodule CaptainFact.SourceTest do
  use CaptainFact.DataCase

  alias CaptainFactWeb.Source

  @valid_attrs %{title: "some content", url: "http://www.lemonde.fr/idees/article/2017/04/24/les-risques-d-une-explosion_5116380_3232.html"}
  @invalid_attrs %{}

  test "changeset with valid attributes" do
    changeset = Source.changeset(%Source{}, @valid_attrs)
    assert changeset.valid?
  end

  test "changeset with invalid attributes" do
    changeset = Source.changeset(%Source{}, @invalid_attrs)
    refute changeset.valid?
  end
end

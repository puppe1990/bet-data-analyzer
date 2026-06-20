defmodule BetDataAnalyzer.SchemasTest do
  use BetDataAnalyzer.DataCase, async: true

  alias BetDataAnalyzer.Leagues.WatchedLeague
  alias BetDataAnalyzer.Fixtures.Fixture
  alias BetDataAnalyzer.ContextPacks.ContextPack

  test "watched league changeset requires sportmonks_id and name" do
    changeset = WatchedLeague.changeset(%WatchedLeague{}, %{})
    refute changeset.valid?
    assert %{sportmonks_id: _, name: _} = errors_on(changeset)
  end

  test "fixture changeset requires core fields" do
    changeset = Fixture.changeset(%Fixture{}, %{})
    refute changeset.valid?
    assert %{sportmonks_id: _, name: _, league_id: _} = errors_on(changeset)
  end

  test "context pack changeset validates status inclusion" do
    changeset = ContextPack.changeset(%ContextPack{}, %{fixture_id: 1, status: "invalid"})
    refute changeset.valid?
    assert "is invalid" in errors_on(changeset).status
  end
end

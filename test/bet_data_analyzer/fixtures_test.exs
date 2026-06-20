defmodule BetDataAnalyzer.FixturesTest do
  use BetDataAnalyzer.DataCase, async: false

  alias BetDataAnalyzer.Fixtures
  alias BetDataAnalyzer.Factory

  test "upsert_from_api/1 inserts fixture from api payload" do
    raw = List.first(BetDataAnalyzer.SportmonksFixtures.fixtures_between_response()["data"])

    assert {:ok, fixture} = Fixtures.upsert_from_api(raw)
    assert fixture.sportmonks_id == 19_415_336
    assert fixture.home_team_name == "Hibernian"
    assert fixture.away_team_name == "Dundee United"
  end

  test "upsert_from_api/1 updates existing fixture" do
    Factory.insert_fixture(%{sportmonks_id: 19_415_336, state: "old"})
    raw = List.first(BetDataAnalyzer.SportmonksFixtures.fixtures_between_response()["data"])

    assert {:ok, updated} = Fixtures.upsert_from_api(raw)
    assert updated.state == "scheduled"
  end

  test "list_upcoming/1 filters by search term" do
    Factory.insert_fixture(%{name: "Hibernian vs Dundee United"})
    Factory.insert_fixture(%{
      name: "Other vs Match",
      sportmonks_id: 99_999,
      home_team_name: "Other",
      away_team_name: "Match"
    })

    results = Fixtures.list_upcoming(search: "Hibernian")
    assert length(results) == 1
    assert hd(results).name =~ "Hibernian"
  end

  test "sync_upcoming_fixtures!/0 returns zero without watched leagues" do
    assert {:ok, 0} = Fixtures.sync_upcoming_fixtures!()
  end

  test "sync_upcoming_fixtures!/0 imports fixtures for watched leagues" do
    Factory.insert_watched_league()

    assert {:ok, count} = Fixtures.sync_upcoming_fixtures!()
    assert count == 1
    assert Fixtures.get_fixture_by_sportmonks_id(19_415_336)
  end
end
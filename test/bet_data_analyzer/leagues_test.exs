defmodule BetDataAnalyzer.LeaguesTest do
  use BetDataAnalyzer.DataCase, async: true

  alias BetDataAnalyzer.Leagues
  alias BetDataAnalyzer.Factory

  test "add_league/1 persists watched league" do
    assert {:ok, league} =
             Leagues.add_league(%{
               "id" => 501,
               "name" => "Premiership",
               "country" => %{"name" => "Scotland"}
             })

    assert league.sportmonks_id == 501
    assert league.country == "Scotland"
  end

  test "add_league/1 rejects duplicate sportmonks_id" do
    Factory.insert_watched_league()

    assert {:error, changeset} =
             Leagues.add_league(%{"id" => 501, "name" => "Premiership"})

    assert "has already been taken" in errors_on(changeset).sportmonks_id
  end

  test "remove_league/1 deletes league" do
    league = Factory.insert_watched_league()
    assert {:ok, _} = Leagues.remove_league(league.id)
    assert Leagues.list_watched_leagues() == []
  end

  test "search_leagues/1 delegates to sportmonks stub" do
    assert {:ok, [%{"name" => "Premiership"} | _]} = Leagues.search_leagues("Scotland")
  end

  test "watched_league_ids/0 returns sportmonks ids" do
    Factory.insert_watched_league(%{sportmonks_id: 777, name: "Test League"})
    assert 777 in Leagues.watched_league_ids()
  end
end

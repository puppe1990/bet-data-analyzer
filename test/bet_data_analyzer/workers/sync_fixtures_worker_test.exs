defmodule BetDataAnalyzer.Workers.SyncFixturesWorkerTest do
  use BetDataAnalyzer.DataCase, async: false

  alias BetDataAnalyzer.Workers.SyncFixturesWorker
  alias BetDataAnalyzer.Factory
  alias BetDataAnalyzer.Fixtures

  test "perform/1 syncs fixtures when leagues are configured" do
    Factory.insert_watched_league()

    assert :ok = SyncFixturesWorker.perform(%Oban.Job{args: %{}})
    assert Fixtures.get_fixture_by_sportmonks_id(19_415_336)
  end

  test "perform/1 succeeds with zero leagues" do
    assert :ok = SyncFixturesWorker.perform(%Oban.Job{args: %{}})
  end
end
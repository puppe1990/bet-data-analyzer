defmodule BetDataAnalyzer.Workers.EnrichFixtureWorkerTest do
  use BetDataAnalyzer.DataCase, async: false

  alias BetDataAnalyzer.Workers.EnrichFixtureWorker
  alias BetDataAnalyzer.ContextPacks
  alias BetDataAnalyzer.Factory

  test "perform/1 enriches fixture and stores context pack" do
    fixture = Factory.insert_fixture()

    assert :ok = EnrichFixtureWorker.perform(%Oban.Job{args: %{"fixture_id" => fixture.id}})

    pack = ContextPacks.latest_for_fixture(fixture.id)
    assert pack.status == "complete"
  end
end
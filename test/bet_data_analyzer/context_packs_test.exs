defmodule BetDataAnalyzer.ContextPacksTest do
  use BetDataAnalyzer.DataCase, async: true

  alias BetDataAnalyzer.ContextPacks
  alias BetDataAnalyzer.Factory

  test "run_enrichment/1 persists complete context pack" do
    fixture = Factory.insert_fixture()

    pack = ContextPacks.run_enrichment(fixture)

    assert pack.status == "complete"
    assert pack.progress == 100
    assert pack.api_calls > 0
    assert get_in(pack.data, ["prompt", "user"]) =~ fixture.name
  end

  test "run_enrichment/1 stores failure for inaccessible fixture" do
    fixture = Factory.insert_fixture(%{sportmonks_id: 99_999_999})

    pack = ContextPacks.run_enrichment(fixture)

    assert pack.status == "failed"
    assert pack.error_message =~ "SportMonks"
  end

  test "latest_for_fixture/1 returns most recent pack" do
    fixture = Factory.insert_fixture()
    Factory.insert_context_pack(fixture, %{status: "failed", progress: 0, data: nil})
    latest = Factory.insert_context_pack(fixture, %{status: "complete"})

    assert ContextPacks.latest_for_fixture(fixture.id).id == latest.id
  end

  test "subscribe/1 receives broadcast on enrichment" do
    fixture = Factory.insert_fixture()
    ContextPacks.subscribe(fixture.id)

    ContextPacks.run_enrichment(fixture)

    assert_received {:context_pack, %{status: "complete"}}
  end
end
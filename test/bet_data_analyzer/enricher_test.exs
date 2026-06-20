defmodule BetDataAnalyzer.EnricherTest do
  use ExUnit.Case, async: true

  alias BetDataAnalyzer.Enricher
  alias BetDataAnalyzer.Factory

  test "enrich/2 builds complete context pack json" do
    fixture = %BetDataAnalyzer.Fixtures.Fixture{
      sportmonks_id: 19_415_336,
      name: "Hibernian vs Dundee United",
      league_name: "Premiership",
      starting_at: ~U[2026-06-20 14:00:00Z],
      state: "scheduled",
      has_odds: true,
      home_team_id: 66,
      away_team_id: 282,
      home_team_name: "Hibernian",
      away_team_name: "Dundee United",
      season_id: 25_083
    }

    assert {:ok, data} = Enricher.enrich(fixture)

    assert data["meta"]["fixture_id"] == 19_415_336
    assert data["home_team"]["form"] == "WD"
    assert data["away_team"]["form"] == "LW"
    assert length(data["head_to_head"]) == 1
    assert length(data["home_team"]["recent_matches"]) == 1
    assert length(data["home_team"]["squad"]) == 1
    assert length(data["home_team"]["injuries"]) == 1
    assert get_in(data, ["odds", "markets"]) != []
    assert get_in(data, ["predictions", "winner"]) == "home"
    assert is_binary(data["prompt"]["user"])
  end

  test "enrich/2 returns api error for inaccessible fixture" do
    fixture = Factory.build_fixture_struct(%{sportmonks_id: 99_999_999})

    assert {:error, {:api_error, %{"message" => _}}} = Enricher.enrich(fixture)
  end

  test "enrich/2 calls progress callback" do
    fixture = Factory.build_fixture_struct(%{})

    {:ok, _data} =
      Enricher.enrich(fixture, fn payload ->
        send(self(), {:progress, payload})
      end)

    assert_received {:progress, %{step: "fixture", progress: 10}}
    assert_received {:progress, %{step: "complete", progress: 100}}
  end
end

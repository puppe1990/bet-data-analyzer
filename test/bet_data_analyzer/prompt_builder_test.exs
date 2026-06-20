defmodule BetDataAnalyzer.PromptBuilderTest do
  use ExUnit.Case, async: true

  alias BetDataAnalyzer.PromptBuilder
  alias BetDataAnalyzer.Enricher

  test "build/2 produces JSON with prompt keys" do
    fixture = %BetDataAnalyzer.Fixtures.Fixture{
      sportmonks_id: 123,
      name: "Team A vs Team B",
      league_name: "Test League",
      starting_at: ~U[2026-06-19 20:00:00Z],
      state: "scheduled",
      has_odds: true,
      home_team_name: "Team A",
      away_team_name: "Team B"
    }

    enriched = %Enricher.Result{
      home_team: %Enricher.TeamData{
        id: 1,
        name: "Team A",
        form: "WWDLW",
        position: 2,
        recent_matches: [%{"name" => "A vs C"}],
        season_stats: [%{"type" => "goals", "value" => 10}],
        squad: [%{"player" => "Player 1"}],
        injuries: []
      },
      away_team: %Enricher.TeamData{
        id: 2,
        name: "Team B",
        form: "LDWWL",
        position: 1,
        recent_matches: [],
        season_stats: [],
        squad: [],
        injuries: [%{"player" => "Injured"}]
      },
      head_to_head: [%{"name" => "A vs B"}],
      standings: %{"home_position" => 2, "away_position" => 1},
      odds: %{"markets" => [%{"market" => "1X2", "bookmaker" => "Test"}]},
      predictions: %{"value" => true},
      api_calls: 8
    }

    result = PromptBuilder.build(enriched, fixture)

    assert result["meta"]["fixture_id"] == 123
    assert result["home_team"]["form"] == "WWDLW"
    assert is_binary(result["prompt"]["system"])
    assert String.contains?(result["prompt"]["user"], "Team A vs Team B")
  end
end
defmodule BetDataAnalyzer.SportmonksFixtures do
  @moduledoc false

  def league_search_response do
    %{
      "data" => [
        %{
          "id" => 501,
          "name" => "Premiership",
          "country" => %{"name" => "Scotland"},
          "image_path" => nil
        }
      ]
    }
  end

  def fixtures_between_response do
    %{
      "data" => [
        %{
          "id" => 19_415_336,
          "name" => "Hibernian vs Dundee United",
          "league_id" => 501,
          "season_id" => 25_083,
          "starting_at" => future_kickoff(),
          "has_odds" => true,
          "participants" => [
            %{"id" => 66, "name" => "Hibernian", "meta" => %{"location" => "home"}},
            %{"id" => 282, "name" => "Dundee United", "meta" => %{"location" => "away"}}
          ],
          "league" => %{"id" => 501, "name" => "Premiership"},
          "state" => %{"name" => "scheduled"}
        }
      ]
    }
  end

  def fixture_detail_response do
    %{
      "data" => %{
        "id" => 19_415_336,
        "name" => "Hibernian vs Dundee United",
        "season_id" => 25_083,
        "has_odds" => true,
        "participants" => [
          %{"id" => 66, "name" => "Hibernian", "meta" => %{"location" => "home"}},
          %{"id" => 282, "name" => "Dundee United", "meta" => %{"location" => "away"}}
        ],
        "odds" => [
          %{
            "market_id" => 1,
            "bookmaker_id" => 2,
            "market_description" => "1X2",
            "bookmaker" => %{"name" => "Bet365"},
            "label" => "Home",
            "value" => 2.1
          }
        ],
        "predictions" => %{"winner" => "home"},
        "sidelined" => [
          %{
            "participant_id" => 66,
            "category" => "injury",
            "player" => %{"display_name" => "John Injured"}
          }
        ]
      }
    }
  end

  def head_to_head_response do
    %{
      "data" => [
        %{
          "starting_at" => "2025-01-01 15:00:00",
          "name" => "Hibernian vs Dundee United",
          "result_info" => "Hibernian won",
          "league" => %{"name" => "Premiership"}
        }
      ]
    }
  end

  def standings_response do
    %{
      "data" => [
        %{
          "participant_id" => 66,
          "position" => 3,
          "points" => 55,
          "form" => [%{"form" => "win"}, %{"form" => "draw"}]
        },
        %{
          "participant_id" => 282,
          "position" => 4,
          "points" => 50,
          "form" => [%{"form" => "loss"}, %{"form" => "win"}]
        }
      ]
    }
  end

  def season_stats_response do
    %{
      "data" => [
        %{
          "details" => [
            %{"type" => %{"name" => "Goals"}, "type_id" => 52, "value" => %{"total" => 45}}
          ]
        }
      ]
    }
  end

  def squad_response do
    %{
      "data" => [
        %{
          "jersey_number" => 9,
          "position_id" => 27,
          "player" => %{"display_name" => "Test Striker"}
        }
      ]
    }
  end

  def recent_fixtures_response(team_id) do
    opponent = if team_id == 66, do: "Dundee United", else: "Hibernian"

    %{
      "data" => [
        %{
          "starting_at" => "2026-05-01 14:00:00",
          "name" => "Recent Match",
          "league" => %{"name" => "Premiership"},
          "participants" => [
            %{"id" => team_id, "name" => "Team", "meta" => %{"location" => "home"}},
            %{"id" => 999, "name" => opponent, "meta" => %{"location" => "away"}}
          ],
          "scores" => [
            %{"score" => %{"participant" => "home", "goals" => 2}},
            %{"score" => %{"participant" => "away", "goals" => 1}}
          ]
        }
      ]
    }
  end

  def api_error_response do
    %{
      "message" =>
        "No result(s) found matching your request. Either the query did not return any results or you don't have access to it via your current subscription."
    }
  end

  defp future_kickoff do
    DateTime.utc_now()
    |> DateTime.add(86_400, :second)
    |> Calendar.strftime("%Y-%m-%d %H:%M:%S")
  end
end
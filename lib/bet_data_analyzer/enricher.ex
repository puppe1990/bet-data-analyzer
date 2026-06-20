defmodule BetDataAnalyzer.Enricher do
  @moduledoc """
  Orchestrates SportMonks API calls to build a complete match context.
  """

  alias BetDataAnalyzer.Sportmonks.Api
  alias BetDataAnalyzer.PromptBuilder

  defmodule TeamData do
    defstruct [:id, :name, :form, :position, :recent_matches, :season_stats, :squad, :injuries]
  end

  defmodule Result do
    defstruct [
      :home_team,
      :away_team,
      :head_to_head,
      :standings,
      :odds,
      :predictions,
      :fixture_raw,
      :api_calls
    ]
  end

  def enrich(fixture, on_progress \\ fn _ -> :ok end) do
    api_calls = :counters.new(1, [])

    on_progress.(%{step: "fixture", progress: 10})

    with {:ok, fixture_raw} <- fetch_fixture(api_calls, fixture.sportmonks_id),
         {home_id, away_id, season_id} <- extract_ids(fixture_raw, fixture),
         {:ok, h2h} <- fetch_optional(api_calls, fn -> Api.head_to_head(home_id, away_id) end),
         {:ok, standings_raw} <- fetch_standings(api_calls, season_id),
         {:ok, home_stats} <- fetch_optional(api_calls, fn -> Api.season_statistics(home_id) end),
         {:ok, away_stats} <- fetch_optional(api_calls, fn -> Api.season_statistics(away_id) end),
         {:ok, home_squad} <- fetch_optional(api_calls, fn -> Api.team_squad(home_id) end),
         {:ok, away_squad} <- fetch_optional(api_calls, fn -> Api.team_squad(away_id) end),
         {:ok, home_recent} <- fetch_optional(api_calls, fn -> Api.team_recent_fixtures(home_id) end),
         {:ok, away_recent} <- fetch_optional(api_calls, fn -> Api.team_recent_fixtures(away_id) end) do
      on_progress.(%{step: "building", progress: 90})

      standings = parse_standings(standings_raw, home_id, away_id)
      injuries = parse_injuries(fixture_raw)

      home_team = %TeamData{
        id: home_id,
        name: fixture.home_team_name,
        form: standings.home_form,
        position: standings.home_position,
        recent_matches: parse_recent(home_recent, home_id),
        season_stats: extract_stats(home_stats),
        squad: parse_squad(home_squad),
        injuries: Enum.filter(injuries, &(&1["team_id"] == home_id))
      }

      away_team = %TeamData{
        id: away_id,
        name: fixture.away_team_name,
        form: standings.away_form,
        position: standings.away_position,
        recent_matches: parse_recent(away_recent, away_id),
        season_stats: extract_stats(away_stats),
        squad: parse_squad(away_squad),
        injuries: Enum.filter(injuries, &(&1["team_id"] == away_id))
      }

      enriched = %Result{
        home_team: home_team,
        away_team: away_team,
        head_to_head: parse_h2h(h2h),
        standings: %{
          "home_position" => standings.home_position,
          "away_position" => standings.away_position,
          "home_points" => standings.home_points,
          "away_points" => standings.away_points
        },
        odds: parse_odds(fixture_raw),
        predictions: get_in(fixture_raw, ["data", "predictions"]),
        fixture_raw: fixture_raw,
        api_calls: :counters.get(api_calls, 1)
      }

      on_progress.(%{step: "complete", progress: 100})

      {:ok, PromptBuilder.build(enriched, fixture)}
    else
      {:error, reason} -> {:error, reason}
    end
  end

  defp tracked_call(counter, fun) do
    result = fun.()
    :counters.add(counter, 1, 1)
    result
  end

  defp fetch_fixture(counter, fixture_id) do
    case tracked_call(counter, fn -> Api.fixture_by_id(fixture_id, premium_includes: true) end) do
      {:error, {:http_error, 403, %{"message" => msg}}} when is_binary(msg) ->
        if String.contains?(msg, "include") do
          tracked_call(counter, fn -> Api.fixture_by_id(fixture_id, premium_includes: false) end)
        else
          {:error, {:http_error, 403, %{"message" => msg}}}
        end

      other ->
        other
    end
  end

  defp fetch_optional(counter, fun) do
    case tracked_call(counter, fun) do
      {:ok, result} -> {:ok, result}
      {:error, _} -> {:ok, %{"data" => []}}
    end
  end

  defp fetch_standings(_counter, nil), do: {:ok, %{"data" => []}}

  defp fetch_standings(counter, season_id) do
    fetch_optional(counter, fn -> Api.standings_by_season(season_id) end)
  end

  defp extract_ids(%{"data" => data}, fixture) do
    participants = Map.get(data, "participants", [])

    home =
      Enum.find(participants, &(&1["meta"]["location"] == "home")) ||
        %{"id" => fixture.home_team_id}

    away =
      Enum.find(participants, &(&1["meta"]["location"] == "away")) ||
        %{"id" => fixture.away_team_id}

    {home["id"], away["id"], data["season_id"] || fixture.season_id}
  end

  defp parse_standings(%{"data" => rows}, home_id, away_id) when is_list(rows) do
    home_row = find_standing(rows, home_id)
    away_row = find_standing(rows, away_id)

    %{
      home_position: get_in(home_row, ["position"]),
      away_position: get_in(away_row, ["position"]),
      home_points: get_in(home_row, ["points"]),
      away_points: get_in(away_row, ["points"]),
      home_form: form_string(home_row),
      away_form: form_string(away_row)
    }
  end

  defp parse_standings(_, _, _) do
    %{home_position: nil, away_position: nil, home_points: nil, away_points: nil, home_form: nil, away_form: nil}
  end

  defp find_standing(rows, team_id) do
    Enum.find(rows, fn row ->
      participant_id(row) == team_id
    end)
  end

  defp participant_id(%{"participant_id" => id}), do: id

  defp participant_id(%{"participant" => %{"id" => id}}), do: id
  defp participant_id(_), do: nil

  defp form_string(nil), do: nil

  defp form_string(row) do
    case Map.get(row, "form") do
      forms when is_list(forms) ->
        forms
        |> Enum.take(5)
        |> Enum.map_join("", fn
          %{"form" => f} -> form_letter(f)
          f when is_binary(f) -> String.upcase(String.first(f) || "")
          _ -> "?"
        end)

      form when is_binary(form) ->
        form

      _ ->
        nil
    end
  end

  defp form_letter("win"), do: "W"
  defp form_letter("draw"), do: "D"
  defp form_letter("loss"), do: "L"
  defp form_letter(other) when is_binary(other), do: String.upcase(String.first(other) || "?")
  defp form_letter(_), do: "?"

  defp parse_recent(%{"data" => fixtures}, team_id) do
    fixtures
    |> Enum.take(10)
    |> Enum.map(fn f ->
      opponent = opponent_name(f, team_id)

      %{
        "date" => f["starting_at"],
        "name" => f["name"],
        "opponent" => opponent,
        "result" => score_summary(f, team_id),
        "league" => get_in(f, ["league", "name"])
      }
    end)
  end

  defp parse_recent(_, _), do: []

  defp opponent_name(fixture, team_id) do
    fixture
    |> Map.get("participants", [])
    |> Enum.reject(&(&1["id"] == team_id))
    |> List.first()
    |> case do
      %{"name" => name} -> name
      _ -> "Desconhecido"
    end
  end

  defp score_summary(fixture, team_id) do
    scores = Map.get(fixture, "scores", [])

    home_score =
      scores
      |> Enum.find(fn s -> get_in(s, ["score", "participant"]) == "home" end)
      |> get_in(["score", "goals"])

    away_score =
      scores
      |> Enum.find(fn s -> get_in(s, ["score", "participant"]) == "away" end)
      |> get_in(["score", "goals"])

    location =
      fixture
      |> Map.get("participants", [])
      |> Enum.find(&(&1["id"] == team_id))
      |> get_in(["meta", "location"])

    case {location, home_score, away_score} do
      {"home", h, a} when is_integer(h) and is_integer(a) -> "#{h}-#{a}"
      {"away", h, a} when is_integer(h) and is_integer(a) -> "#{a}-#{h}"
      _ -> "N/A"
    end
  end

  defp extract_stats(%{"data" => stats}) when is_list(stats) do
    stats
    |> List.first()
    |> case do
      %{"details" => details} when is_list(details) ->
        Enum.map(details, fn d ->
          %{
            "type" => get_in(d, ["type", "name"]) || d["type_id"],
            "value" => d["value"]
          }
        end)

      _ ->
        []
    end
    |> Enum.reject(&is_nil(&1["value"]))
  end

  defp extract_stats(_), do: []

  defp parse_squad(%{"data" => squad}) when is_list(squad) do
    Enum.map(squad, fn entry ->
      %{
        "player" => get_in(entry, ["player", "display_name"]) || get_in(entry, ["player", "name"]),
        "position" => entry["position_id"],
        "jersey_number" => entry["jersey_number"]
      }
    end)
  end

  defp parse_squad(_), do: []

  defp parse_injuries(%{"data" => %{"sidelined" => sidelined}}) when is_list(sidelined) do
    Enum.map(sidelined, fn s ->
      %{
        "team_id" => s["participant_id"],
        "player" => get_in(s, ["player", "display_name"]) || get_in(s, ["player", "name"]),
        "reason" => s["category"]
      }
    end)
  end

  defp parse_injuries(_), do: []

  defp parse_h2h(%{"data" => fixtures}) when is_list(fixtures) do
    Enum.take(fixtures, 5)
    |> Enum.map(fn f ->
      %{
        "date" => f["starting_at"],
        "name" => f["name"],
        "result" => f["result_info"],
        "league" => get_in(f, ["league", "name"])
      }
    end)
  end

  defp parse_h2h(_), do: []

  defp parse_odds(%{"data" => %{"odds" => odds}}) when is_list(odds) do
    markets =
      odds
      |> Enum.group_by(fn o -> {o["market_id"], o["bookmaker_id"]} end)
      |> Enum.map(fn {{market_id, bookmaker_id}, entries} ->
        %{
          "market" => market_name(entries) || "market_#{market_id}",
          "bookmaker" => bookmaker_name(entries) || "bookmaker_#{bookmaker_id}",
          "selections" =>
            Enum.map(entries, fn e ->
              %{
                "label" => e["label"] || e["name"],
                "value" => e["value"],
                "probability" => e["probability"]
              }
            end)
        }
      end)

    %{"markets" => markets}
  end

  defp parse_odds(_), do: %{"markets" => []}

  defp market_name([%{"market_description" => name} | _]), do: name
  defp market_name(_), do: nil

  defp bookmaker_name([%{"bookmaker" => %{"name" => name}} | _]), do: name
  defp bookmaker_name(_), do: nil
end
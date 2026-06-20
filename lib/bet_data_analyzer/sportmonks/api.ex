defmodule BetDataAnalyzer.Sportmonks.Api do
  @moduledoc """
  High-level SportMonks API helpers.
  """

  @recent_matches_limit 10

  defp http, do: Application.fetch_env!(:bet_data_analyzer, :sportmonks_http)

  def search_leagues(query) when is_binary(query) and byte_size(query) > 0 do
    with {:ok, %{"data" => data}} <- http().get("/leagues/search/#{URI.encode(query)}") do
      {:ok, data}
    end
  end

  def search_leagues(_), do: {:ok, []}

  def fixtures_between(start_date, end_date, league_ids) when is_list(league_ids) do
    leagues_filter = Enum.join(league_ids, ",")

    includes = "participants;league;state"

    http().get(
      "/fixtures/between/#{start_date}/#{end_date}",
      include: includes,
      filters: "fixtureLeagues:#{leagues_filter}"
    )
  end

  def fixture_by_id(fixture_id, opts \\ []) do
    premium? = Keyword.get(opts, :premium_includes, true)

    base = [
      "participants",
      "statistics.type",
      "lineups.player",
      "formations",
      "sidelined.player",
      "league",
      "season",
      "venue",
      "state",
      "scores"
    ]

    includes =
      if premium? do
        base ++ ["odds", "predictions"]
      else
        base
      end
      |> Enum.join(";")

    http().get("/fixtures/#{fixture_id}", include: includes)
  end

  def head_to_head(team1_id, team2_id) do
    http().get("/fixtures/head-to-head/#{team1_id}/#{team2_id}", include: "participants;scores;league")
  end

  def standings_by_season(season_id) do
    http().get("/standings/seasons/#{season_id}", include: "participant;form")
  end

  def season_statistics(team_id) do
    http().get("/statistics/seasons/teams/#{team_id}", include: "details.type")
  end

  def team_squad(team_id) do
    http().get("/squads/teams/#{team_id}", include: "player;team")
  end

  def team_recent_fixtures(team_id, days_back \\ 120) do
    end_date = Date.utc_today()
    start_date = Date.add(end_date, -days_back)

    http().get(
      "/fixtures/between/#{format_date(start_date)}/#{format_date(end_date)}/#{team_id}",
      include: "participants;scores;statistics.type;league",
      per_page: @recent_matches_limit
    )
  end

  defp format_date(%Date{} = date), do: Date.to_iso8601(date)
end
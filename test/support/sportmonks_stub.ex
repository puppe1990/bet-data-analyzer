defmodule BetDataAnalyzer.Sportmonks.Stub do
  @moduledoc false
  @behaviour BetDataAnalyzer.Sportmonks.Http

  alias BetDataAnalyzer.SportmonksFixtures, as: Fixtures

  def get(path, params \\ [])

  @impl true
  def get("/leagues/search/" <> _query, _params), do: {:ok, Fixtures.league_search_response()}

  def get("/fixtures/between/" <> rest, _params) do
    cond do
      String.contains?(rest, "/66") -> {:ok, Fixtures.recent_fixtures_response(66)}
      String.contains?(rest, "/282") -> {:ok, Fixtures.recent_fixtures_response(282)}
      true -> {:ok, Fixtures.fixtures_between_response()}
    end
  end

  def get("/fixtures/head-to-head/" <> _, _params), do: {:ok, Fixtures.head_to_head_response()}

  def get("/fixtures/" <> id, _params) when id not in ["between", "head-to-head", "search"] do
    case id do
      "99999999" -> {:error, {:api_error, Fixtures.api_error_response()}}
      _ -> {:ok, Fixtures.fixture_detail_response()}
    end
  end

  def get("/standings/seasons/" <> _, _params), do: {:ok, Fixtures.standings_response()}
  def get("/statistics/seasons/teams/" <> _, _params), do: {:ok, Fixtures.season_stats_response()}
  def get("/squads/teams/" <> _, _params), do: {:ok, Fixtures.squad_response()}

  def get(path, _params), do: {:error, {:unknown_path, path}}
end

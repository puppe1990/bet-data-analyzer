defmodule BetDataAnalyzer.Factory do
  @moduledoc false

  alias BetDataAnalyzer.Repo
  alias BetDataAnalyzer.Leagues.WatchedLeague
  alias BetDataAnalyzer.Fixtures.Fixture
  alias BetDataAnalyzer.ContextPacks.ContextPack

  def insert_watched_league(attrs \\ %{}) do
    defaults = %{
      sportmonks_id: 501,
      name: "Premiership",
      country: "Scotland"
    }

    %WatchedLeague{}
    |> WatchedLeague.changeset(Map.merge(defaults, attrs))
    |> Repo.insert!()
  end

  def insert_fixture(attrs \\ %{}) do
    kickoff = DateTime.utc_now() |> DateTime.add(86_400, :second) |> DateTime.truncate(:second)

    defaults = %{
      sportmonks_id: 19_415_336,
      name: "Hibernian vs Dundee United",
      league_id: 501,
      league_name: "Premiership",
      season_id: 25_083,
      home_team_id: 66,
      away_team_id: 282,
      home_team_name: "Hibernian",
      away_team_name: "Dundee United",
      starting_at: kickoff,
      state: "scheduled",
      has_odds: true,
      raw: %{}
    }

    %Fixture{}
    |> Fixture.changeset(Map.merge(defaults, attrs))
    |> Repo.insert!()
  end

  def build_fixture_struct(attrs \\ %{}) do
    kickoff = DateTime.utc_now() |> DateTime.add(86_400, :second) |> DateTime.truncate(:second)

    struct(
      Fixture,
      Map.merge(
        %{
          sportmonks_id: 19_415_336,
          name: "Hibernian vs Dundee United",
          league_name: "Premiership",
          starting_at: kickoff,
          state: "scheduled",
          has_odds: true,
          home_team_id: 66,
          away_team_id: 282,
          home_team_name: "Hibernian",
          away_team_name: "Dundee United",
          season_id: 25_083
        },
        attrs
      )
    )
  end

  def insert_context_pack(fixture, attrs \\ %{}) do
    defaults = %{
      fixture_id: fixture.id,
      status: "complete",
      progress: 100,
      api_calls: 8,
      data: %{
        "fixture" => %{"name" => fixture.name},
        "prompt" => %{"system" => "sys", "user" => "user"}
      }
    }

    %ContextPack{}
    |> ContextPack.changeset(Map.merge(defaults, attrs))
    |> Repo.insert!()
  end
end
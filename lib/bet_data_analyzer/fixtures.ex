defmodule BetDataAnalyzer.Fixtures do
  @moduledoc """
  Context for fixture cache and sync.
  """

  import Ecto.Query, warn: false
  alias BetDataAnalyzer.Repo
  alias BetDataAnalyzer.Fixtures.Fixture
  alias BetDataAnalyzer.Leagues
  alias BetDataAnalyzer.Sportmonks.Api

  def list_upcoming(opts \\ []) do
    league_id = Keyword.get(opts, :league_id)
    search = Keyword.get(opts, :search)

    query =
      from f in Fixture,
        where: f.starting_at >= ^DateTime.utc_now(),
        order_by: [asc: f.starting_at],
        preload: [:context_packs]

    query =
      if league_id do
        from f in query, where: f.league_id == ^league_id
      else
        query
      end

    query =
      if search && search != "" do
        pattern = "%#{String.downcase(search)}%"

        from f in query,
          where:
            fragment("lower(?) LIKE ?", f.name, ^pattern) or
              fragment("lower(?) LIKE ?", f.home_team_name, ^pattern) or
              fragment("lower(?) LIKE ?", f.away_team_name, ^pattern)
      else
        query
      end

    Repo.all(query)
  end

  def get_fixture!(id), do: Repo.get!(Fixture, id) |> Repo.preload(:context_packs)

  def get_fixture_by_sportmonks_id(sportmonks_id) do
    Repo.get_by(Fixture, sportmonks_id: sportmonks_id)
  end

  def sync_upcoming_fixtures! do
    league_ids = Leagues.watched_league_ids()

    if league_ids == [] do
      {:ok, 0}
    else
      start_date = Date.utc_today() |> Date.to_iso8601()
      end_date = Date.utc_today() |> Date.add(7) |> Date.to_iso8601()

      case Api.fixtures_between(start_date, end_date, league_ids) do
        {:ok, %{"data" => fixtures}} ->
          count =
            Enum.reduce(fixtures, 0, fn raw, acc ->
              case upsert_from_api(raw) do
                {:ok, _} -> acc + 1
                _ -> acc
              end
            end)

          {:ok, count}

        {:error, reason} ->
          {:error, reason}
      end
    end
  end

  def upsert_from_api(raw) do
    attrs = parse_fixture(raw)

    case get_fixture_by_sportmonks_id(attrs.sportmonks_id) do
      nil ->
        %Fixture{}
        |> Fixture.changeset(attrs)
        |> Repo.insert()

      fixture ->
        fixture
        |> Fixture.changeset(attrs)
        |> Repo.update()
    end
  end

  defp parse_fixture(raw) do
    participants = Map.get(raw, "participants", [])
    {home, away} = split_participants(participants)

    %{
      sportmonks_id: raw["id"],
      name: raw["name"],
      league_id: get_in(raw, ["league_id"]) || get_in(raw, ["league", "id"]),
      league_name: get_in(raw, ["league", "name"]),
      season_id: raw["season_id"],
      home_team_id: home && home["id"],
      away_team_id: away && away["id"],
      home_team_name: home && home["name"],
      away_team_name: away && away["name"],
      starting_at: parse_datetime(raw["starting_at"]),
      state: state_name(raw),
      has_odds: raw["has_odds"] == true,
      raw: raw
    }
  end

  defp split_participants(participants) do
    home = Enum.find(participants, &(&1["meta"]["location"] == "home"))
    away = Enum.find(participants, &(&1["meta"]["location"] == "away"))
    {home, away}
  end

  defp state_name(%{"state" => %{"name" => name}}), do: name
  defp state_name(_), do: "scheduled"

  defp parse_datetime(nil), do: nil

  defp parse_datetime(value) when is_binary(value) do
    case NaiveDateTime.from_iso8601(String.replace(value, " ", "T") <> "Z") do
      {:ok, naive} -> DateTime.from_naive!(naive, "Etc/UTC")
      _ -> nil
    end
  end
end

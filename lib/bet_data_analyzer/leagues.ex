defmodule BetDataAnalyzer.Leagues do
  @moduledoc """
  Context for watched leagues configuration.
  """

  import Ecto.Query, warn: false
  alias BetDataAnalyzer.Repo
  alias BetDataAnalyzer.Leagues.WatchedLeague
  alias BetDataAnalyzer.Sportmonks.Api

  def list_watched_leagues do
    Repo.all(from l in WatchedLeague, order_by: [asc: l.name])
  end

  def watched_league_ids do
    Repo.all(from l in WatchedLeague, select: l.sportmonks_id)
  end

  def search_leagues(query) do
    Api.search_leagues(query)
  end

  def add_league(%{"id" => id, "name" => name} = league) do
    country = get_in(league, ["country", "name"]) || get_in(league, ["country", "iso2"])
    image = league["image_path"]

    %WatchedLeague{}
    |> WatchedLeague.changeset(%{
      sportmonks_id: id,
      name: name,
      country: country,
      image_path: image
    })
    |> Repo.insert()
  end

  def remove_league(id) do
    WatchedLeague
    |> Repo.get!(id)
    |> Repo.delete()
  end

  def get_watched_league!(id), do: Repo.get!(WatchedLeague, id)
end
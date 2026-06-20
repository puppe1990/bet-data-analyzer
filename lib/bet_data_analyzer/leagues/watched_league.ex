defmodule BetDataAnalyzer.Leagues.WatchedLeague do
  use Ecto.Schema
  import Ecto.Changeset

  schema "watched_leagues" do
    field :sportmonks_id, :integer
    field :name, :string
    field :country, :string
    field :image_path, :string

    timestamps(type: :utc_datetime)
  end

  def changeset(league, attrs) do
    league
    |> cast(attrs, [:sportmonks_id, :name, :country, :image_path])
    |> validate_required([:sportmonks_id, :name])
    |> unique_constraint(:sportmonks_id)
  end
end

defmodule BetDataAnalyzer.Fixtures.Fixture do
  use Ecto.Schema
  import Ecto.Changeset

  schema "fixtures" do
    field :sportmonks_id, :integer
    field :name, :string
    field :league_id, :integer
    field :league_name, :string
    field :season_id, :integer
    field :home_team_id, :integer
    field :away_team_id, :integer
    field :home_team_name, :string
    field :away_team_name, :string
    field :starting_at, :utc_datetime
    field :state, :string, default: "scheduled"
    field :has_odds, :boolean, default: false
    field :raw, :map, default: %{}

    has_many :context_packs, BetDataAnalyzer.ContextPacks.ContextPack

    timestamps(type: :utc_datetime)
  end

  def changeset(fixture, attrs) do
    fixture
    |> cast(attrs, [
      :sportmonks_id,
      :name,
      :league_id,
      :league_name,
      :season_id,
      :home_team_id,
      :away_team_id,
      :home_team_name,
      :away_team_name,
      :starting_at,
      :state,
      :has_odds,
      :raw
    ])
    |> validate_required([:sportmonks_id, :name, :league_id])
    |> unique_constraint(:sportmonks_id)
  end
end
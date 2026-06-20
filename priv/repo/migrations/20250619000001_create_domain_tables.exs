defmodule BetDataAnalyzer.Repo.Migrations.CreateDomainTables do
  use Ecto.Migration

  def up do
    Oban.Migration.up(version: 12)

    create table(:watched_leagues) do
      add :sportmonks_id, :integer, null: false
      add :name, :string, null: false
      add :country, :string
      add :image_path, :string

      timestamps(type: :utc_datetime)
    end

    create unique_index(:watched_leagues, [:sportmonks_id])

    create table(:fixtures) do
      add :sportmonks_id, :integer, null: false
      add :name, :string, null: false
      add :league_id, :integer, null: false
      add :league_name, :string
      add :season_id, :integer
      add :home_team_id, :integer
      add :away_team_id, :integer
      add :home_team_name, :string
      add :away_team_name, :string
      add :starting_at, :utc_datetime
      add :state, :string, default: "scheduled"
      add :has_odds, :boolean, default: false
      add :raw, :map, default: %{}

      timestamps(type: :utc_datetime)
    end

    create unique_index(:fixtures, [:sportmonks_id])
    create index(:fixtures, [:league_id])
    create index(:fixtures, [:starting_at])

    create table(:context_packs) do
      add :fixture_id, references(:fixtures, on_delete: :delete_all), null: false
      add :status, :string, null: false, default: "pending"
      add :progress, :integer, default: 0
      add :data, :map
      add :error_message, :text
      add :api_calls, :integer, default: 0

      timestamps(type: :utc_datetime)
    end

    create index(:context_packs, [:fixture_id])
    create index(:context_packs, [:status])
  end

  def down do
    drop table(:context_packs)
    drop table(:fixtures)
    drop table(:watched_leagues)
    Oban.Migration.down(version: 12)
  end
end
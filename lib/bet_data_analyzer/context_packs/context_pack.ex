defmodule BetDataAnalyzer.ContextPacks.ContextPack do
  use Ecto.Schema
  import Ecto.Changeset

  @statuses ~w(pending processing complete failed)

  schema "context_packs" do
    field :status, :string, default: "pending"
    field :progress, :integer, default: 0
    field :data, :map
    field :error_message, :string
    field :api_calls, :integer, default: 0

    belongs_to :fixture, BetDataAnalyzer.Fixtures.Fixture

    timestamps(type: :utc_datetime)
  end

  def changeset(pack, attrs) do
    pack
    |> cast(attrs, [:fixture_id, :status, :progress, :data, :error_message, :api_calls])
    |> validate_required([:fixture_id, :status])
    |> validate_inclusion(:status, @statuses)
    |> foreign_key_constraint(:fixture_id)
  end
end

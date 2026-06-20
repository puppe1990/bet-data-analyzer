defmodule BetDataAnalyzer.Workers.SyncFixturesWorker do
  use Oban.Worker, queue: :default

  alias BetDataAnalyzer.Fixtures

  @impl Oban.Worker
  def perform(_job) do
    case Fixtures.sync_upcoming_fixtures!() do
      {:ok, _count} -> :ok
      {:error, reason} -> {:error, reason}
    end
  end
end
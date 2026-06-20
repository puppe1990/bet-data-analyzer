defmodule BetDataAnalyzer.Workers.EnrichFixtureWorker do
  use Oban.Worker, queue: :enrich

  alias BetDataAnalyzer.Fixtures
  alias BetDataAnalyzer.ContextPacks

  @impl Oban.Worker
  def perform(%Oban.Job{args: %{"fixture_id" => fixture_id}}) do
    fixture = Fixtures.get_fixture!(fixture_id)

    case ContextPacks.run_enrichment(fixture) do
      %ContextPacks.ContextPack{status: "complete"} -> :ok
      {:error, reason} -> {:error, reason}
    end
  end
end
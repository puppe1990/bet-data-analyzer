defmodule BetDataAnalyzer.ContextPacks do
  @moduledoc """
  Context for enriched match data packs.
  """

  import Ecto.Query, warn: false
  alias BetDataAnalyzer.Repo
  alias BetDataAnalyzer.ContextPacks.ContextPack
  alias BetDataAnalyzer.Enricher
  alias BetDataAnalyzer.Fixtures.Fixture

  @topic "context_pack"

  def subscribe(fixture_id) do
    Phoenix.PubSub.subscribe(BetDataAnalyzer.PubSub, topic(fixture_id))
  end

  def topic(fixture_id), do: "#{@topic}:#{fixture_id}"

  def latest_for_fixture(fixture_id) do
    ContextPack
    |> where([p], p.fixture_id == ^fixture_id)
    |> order_by([p], desc: p.id)
    |> limit(1)
    |> Repo.one()
  end

  def create_pending!(fixture_id) do
    %ContextPack{}
    |> ContextPack.changeset(%{fixture_id: fixture_id, status: "pending", progress: 0})
    |> Repo.insert!()
  end

  def run_enrichment(%Fixture{} = fixture) do
    pack = create_pending!(fixture.id)
    update_progress!(pack, "processing", 5)

    result =
      Enricher.enrich(fixture, fn %{progress: progress, step: step} ->
        update_progress!(pack, "processing", progress)
        broadcast(fixture.id, %{status: "processing", progress: progress, step: step})
      end)

    case result do
      {:ok, data} ->
        pack
        |> ContextPack.changeset(%{
          status: "complete",
          progress: 100,
          data: data,
          api_calls: get_in(data, ["meta", "api_calls"]) || 0
        })
        |> Repo.update!()
        |> tap(fn p -> broadcast(fixture.id, %{status: "complete", progress: 100, pack: p}) end)

      {:error, reason} ->
        message = format_error(reason)

        pack
        |> ContextPack.changeset(%{status: "failed", error_message: message, progress: 0})
        |> Repo.update!()
        |> tap(fn p ->
          broadcast(fixture.id, %{status: "failed", error_message: message, pack: p})
        end)
    end
  end

  def update_progress!(pack, status, progress) do
    pack
    |> ContextPack.changeset(%{status: status, progress: progress})
    |> Repo.update!()
  end

  defp broadcast(fixture_id, payload) do
    Phoenix.PubSub.broadcast(BetDataAnalyzer.PubSub, topic(fixture_id), {:context_pack, payload})
  end

  defp format_error(:missing_api_token),
    do: "SPORTMONKS_API_TOKEN não configurado. Defina a variável de ambiente."

  defp format_error({:http_error, status, body}) do
    "Erro SportMonks HTTP #{status}: #{inspect(body)}"
  end

  defp format_error({:api_error, %{"message" => message}}) do
    "SportMonks: #{message}"
  end

  defp format_error(reason), do: inspect(reason)
end

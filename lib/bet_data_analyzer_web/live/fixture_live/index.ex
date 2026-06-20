defmodule BetDataAnalyzerWeb.FixtureLive.Index do
  use BetDataAnalyzerWeb, :live_view

  alias BetDataAnalyzer.Fixtures
  alias BetDataAnalyzer.Leagues
  alias BetDataAnalyzer.Workers.SyncFixturesWorker

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign(:page_title, "Jogos")
     |> assign(:search, "")
     |> assign(:league_filter, nil)
     |> load_fixtures()}
  end

  @impl true
  def handle_params(params, _uri, socket) do
    search = params["q"] || ""
    league_filter = parse_int(params["league"])

    {:noreply,
     socket
     |> assign(:search, search)
     |> assign(:league_filter, league_filter)
     |> load_fixtures()}
  end

  @impl true
  def handle_event("search", %{"search" => %{"q" => q}}, socket) do
    params = build_params(q, socket.assigns.league_filter)
    {:noreply, push_patch(socket, to: ~p"/fixtures?#{params}")}
  end

  @impl true
  def handle_event("filter_league", %{"league_id" => league_id}, socket) do
    league_filter = if league_id == "", do: nil, else: String.to_integer(league_id)
    params = build_params(socket.assigns.search, league_filter)
    {:noreply, push_patch(socket, to: ~p"/fixtures?#{params}")}
  end

  @impl true
  def handle_event("sync", _params, socket) do
    {:ok, _job} = SyncFixturesWorker.new(%{}) |> Oban.insert()

    {:noreply, put_flash(socket, :info, "Sincronização de jogos enfileirada.")}
  end

  defp load_fixtures(socket) do
    fixtures =
      Fixtures.list_upcoming(
        search: socket.assigns.search,
        league_id: socket.assigns.league_filter
      )

    assign(socket, fixtures: fixtures, leagues: Leagues.list_watched_leagues())
  end

  defp build_params(search, league_filter) do
    %{}
    |> maybe_put("q", search)
    |> maybe_put("league", league_filter)
  end

  defp maybe_put(map, _key, nil), do: map
  defp maybe_put(map, _key, ""), do: map
  defp maybe_put(map, key, value), do: Map.put(map, key, value)

  defp parse_int(nil), do: nil
  defp parse_int(""), do: nil
  defp parse_int(value), do: String.to_integer(value)

  def pack_status(fixture) do
    fixture.context_packs
    |> Enum.sort_by(& &1.inserted_at, {:desc, DateTime})
    |> List.first()
    |> case do
      %{status: "complete"} -> "ready"
      %{status: "processing"} -> "processing"
      %{status: "failed"} -> "failed"
      _ -> "none"
    end
  end
end

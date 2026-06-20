defmodule BetDataAnalyzerWeb.SettingsLive.Index do
  use BetDataAnalyzerWeb, :live_view

  alias BetDataAnalyzer.Leagues

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign(:page_title, "Configurações")
     |> assign(:query, "")
     |> assign(:results, [])
     |> assign(:watched, Leagues.list_watched_leagues())}
  end

  @impl true
  def handle_event("search", %{"search" => %{"q" => q}}, socket) do
    results =
      case Leagues.search_leagues(q) do
        {:ok, leagues} -> filter_already_watched(leagues, socket.assigns.watched)
        _ -> []
      end

    {:noreply, assign(socket, query: q, results: results)}
  end

  @impl true
  def handle_event("add_league", %{"league" => league_json}, socket) do
    league = Jason.decode!(league_json)

    case Leagues.add_league(league) do
      {:ok, _} ->
        {:noreply,
         socket
         |> assign(:watched, Leagues.list_watched_leagues())
         |> assign(:results, [])
         |> put_flash(:info, "#{league["name"]} adicionada.")}

      {:error, _} ->
        {:noreply, put_flash(socket, :error, "Liga já adicionada ou erro ao salvar.")}
    end
  end

  @impl true
  def handle_event("remove_league", %{"id" => id}, socket) do
    Leagues.remove_league(id)

    {:noreply,
     socket
     |> assign(:watched, Leagues.list_watched_leagues())
     |> put_flash(:info, "Liga removida.")}
  end

  defp filter_already_watched(leagues, watched) do
    watched_ids = MapSet.new(watched, & &1.sportmonks_id)

    Enum.reject(leagues, fn l -> MapSet.member?(watched_ids, l["id"]) end)
  end
end
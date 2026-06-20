defmodule BetDataAnalyzerWeb.SettingsLiveTest do
  use BetDataAnalyzerWeb.LiveCase, async: false

  import Phoenix.LiveViewTest

  alias BetDataAnalyzer.Factory
  alias BetDataAnalyzer.Leagues

  test "settings page lists watched leagues", %{conn: conn} do
    league = Factory.insert_watched_league()

    {:ok, _view, html} = live(conn, ~p"/settings")

    assert html =~ "Ligas"
    assert html =~ league.name
  end

  test "search shows leagues to add", %{conn: conn} do
    {:ok, view, _html} = live(conn, ~p"/settings")

    html =
      view
      |> form("form", search: %{q: "Scotland"})
      |> render_change()

    assert html =~ "Premiership"
  end

  test "add_league event persists league", %{conn: conn} do
    {:ok, view, _html} = live(conn, ~p"/settings")

    view
    |> form("form", search: %{q: "Scotland"})
    |> render_change()

    view
    |> element("button", "Premiership")
    |> render_click()

    assert length(Leagues.list_watched_leagues()) == 1
  end

  test "remove_league event deletes league", %{conn: conn} do
    Factory.insert_watched_league()

    {:ok, view, _html} = live(conn, ~p"/settings")

    view
    |> element("button", "Remover")
    |> render_click()

    assert Leagues.list_watched_leagues() == []
  end
end
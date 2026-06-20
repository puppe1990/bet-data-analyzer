defmodule BetDataAnalyzerWeb.FixtureLiveTest do
  use BetDataAnalyzerWeb.LiveCase, async: false

  import Phoenix.LiveViewTest

  alias BetDataAnalyzer.Factory

  test "index lists upcoming fixtures", %{conn: conn} do
    fixture = Factory.insert_fixture()

    {:ok, _view, html} = live(conn, ~p"/fixtures")

    assert html =~ "Jogos"
    assert html =~ fixture.name
  end

  test "index sync event enqueues job", %{conn: conn} do
    {:ok, view, _html} = live(conn, ~p"/fixtures")

    assert view |> element("button", "Sincronizar") |> render_click() =~ "Sincronização"
  end

  test "show displays fixture and compiles data", %{conn: conn} do
    fixture = Factory.insert_fixture()

    {:ok, view, html} = live(conn, ~p"/fixtures/#{fixture.id}")

    assert html =~ fixture.name
    assert html =~ "Compilar dados"

    render_click(view, "compile")

    assert render(view) =~ "Compilação enfileirada" or render(view) =~ "Pronto"
  end

  test "show copy events push clipboard payload", %{conn: conn} do
    fixture = Factory.insert_fixture()
    Factory.insert_context_pack(fixture)

    {:ok, view, _html} = live(conn, ~p"/fixtures/#{fixture.id}")

    assert render_click(view, "copy_json") =~ "JSON copiado"
    assert render_click(view, "copy_prompt") =~ "Prompt copiado"
  end
end
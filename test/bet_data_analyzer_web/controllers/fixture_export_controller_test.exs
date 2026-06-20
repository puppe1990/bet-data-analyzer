defmodule BetDataAnalyzerWeb.FixtureExportControllerTest do
  use BetDataAnalyzerWeb.ConnCase, async: true

  alias BetDataAnalyzer.Factory

  test "exports json when context pack is complete", %{conn: conn} do
    fixture = Factory.insert_fixture()
    Factory.insert_context_pack(fixture)

    conn = get(conn, ~p"/fixtures/#{fixture.id}/export")

    assert response_content_type(conn, :json)
    assert json_response(conn, 200)["fixture"]["name"] == fixture.name
  end

  test "redirects when context pack is missing", %{conn: conn} do
    fixture = Factory.insert_fixture()

    conn = get(conn, ~p"/fixtures/#{fixture.id}/export")

    assert redirected_to(conn) == ~p"/fixtures/#{fixture.id}"
    assert Phoenix.Flash.get(conn.assigns.flash, :error) =~ "compilado"
  end
end
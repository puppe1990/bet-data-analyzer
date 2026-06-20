defmodule BetDataAnalyzerWeb.FixtureComponentsTest do
  use BetDataAnalyzerWeb.ConnCase, async: true
  import Phoenix.LiveViewTest
  import BetDataAnalyzerWeb.FixtureComponents

  test "format_kickoff/1 formats datetime in Sao Paulo timezone" do
    dt = ~U[2026-06-20 18:00:00Z]
    assert format_kickoff(dt) =~ "20/06"
  end

  test "format_kickoff/1 returns dash for nil" do
    assert format_kickoff(nil) == "—"
  end

  test "status_label/1 translates statuses" do
    assert status_label("complete") == "Pronto"
    assert status_label("processing") == "Compilando..."
    assert status_label("unknown") == "Não compilado"
  end

  test "fixture_badge/1 renders badge" do
    html =
      rendered_to_string(fixture_badge(%{status: "ready"}))

    assert html =~ "Pronto"
    assert html =~ "badge-success"
  end
end

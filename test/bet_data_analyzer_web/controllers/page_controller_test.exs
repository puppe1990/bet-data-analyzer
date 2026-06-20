defmodule BetDataAnalyzerWeb.PageControllerTest do
  use BetDataAnalyzerWeb.ConnCase

  test "GET / shows fixtures dashboard", %{conn: conn} do
    conn = get(conn, ~p"/")
    assert html_response(conn, 200) =~ "Bet Data Analyzer"
    assert html_response(conn, 200) =~ "Jogos"
  end
end

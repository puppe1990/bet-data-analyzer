defmodule BetDataAnalyzerWeb.FixtureExportController do
  use BetDataAnalyzerWeb, :controller

  alias BetDataAnalyzer.Fixtures
  alias BetDataAnalyzer.ContextPacks

  def show(conn, %{"id" => id}) do
    fixture = Fixtures.get_fixture!(id)
    pack = ContextPacks.latest_for_fixture(fixture.id)

    case pack do
      %{status: "complete", data: data} when is_map(data) ->
        json = Jason.encode!(data, pretty: true)

        conn
        |> put_resp_content_type("application/json")
        |> put_resp_header(
          "content-disposition",
          ~s(attachment; filename="fixture-#{fixture.sportmonks_id}.json")
        )
        |> send_resp(200, json)

      _ ->
        conn
        |> put_flash(:error, "Context pack ainda não compilado.")
        |> redirect(to: ~p"/fixtures/#{id}")
    end
  end
end
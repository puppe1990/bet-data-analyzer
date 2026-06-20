defmodule BetDataAnalyzer.Sportmonks.ApiTest do
  use ExUnit.Case, async: true

  alias BetDataAnalyzer.Sportmonks.Api

  test "search_leagues/1 returns leagues from stub" do
    assert {:ok, [%{"name" => "Premiership"} | _]} = Api.search_leagues("Scotland")
  end

  test "search_leagues/1 returns empty list for blank query" do
    assert {:ok, []} = Api.search_leagues("")
  end

  test "fixtures_between/3 returns fixtures" do
    start = Date.utc_today() |> Date.to_iso8601()
    finish = Date.utc_today() |> Date.add(7) |> Date.to_iso8601()

    assert {:ok, %{"data" => [_ | _]}} = Api.fixtures_between(start, finish, [501])
  end

  test "fixture_by_id/2 returns fixture detail" do
    assert {:ok, %{"data" => %{"id" => 19_415_336}}} = Api.fixture_by_id(19_415_336)
  end

  test "fixture_by_id/2 returns api error for inaccessible fixture" do
    assert {:error, {:api_error, %{"message" => _}}} = Api.fixture_by_id(99_999_999)
  end
end

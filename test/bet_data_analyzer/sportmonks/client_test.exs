defmodule BetDataAnalyzer.Sportmonks.ClientTest do
  use ExUnit.Case, async: false

  alias BetDataAnalyzer.Sportmonks.Client

  setup do
    bypass = Bypass.open()

    original_token = Application.get_env(:bet_data_analyzer, :sportmonks_api_token)
    original_base = Application.get_env(:bet_data_analyzer, :sportmonks_base_url)

    Application.put_env(:bet_data_analyzer, :sportmonks_api_token, "test-token")
    Application.put_env(:bet_data_analyzer, :sportmonks_base_url, "http://127.0.0.1:#{bypass.port}/v3/football")

    on_exit(fn ->
      Application.put_env(:bet_data_analyzer, :sportmonks_api_token, original_token)
      Application.put_env(:bet_data_analyzer, :sportmonks_base_url, original_base)
    end)

    {:ok, bypass: bypass}
  end

  test "get/2 returns error when token is missing", %{bypass: _} do
    Application.put_env(:bet_data_analyzer, :sportmonks_api_token, nil)
    assert {:error, :missing_api_token} = Client.get("/fixtures/1")
  end

  test "get/2 parses successful data response", %{bypass: bypass} do
    Bypass.expect_once(bypass, "GET", "/v3/football/fixtures/1", fn conn ->
      conn
      |> Plug.Conn.put_resp_content_type("application/json")
      |> Plug.Conn.resp(200, Jason.encode!(%{"data" => %{"id" => 1}}))
    end)

    assert {:ok, %{"data" => %{"id" => 1}}} = Client.get("/fixtures/1")
  end

  test "get/2 parses api error message response", %{bypass: bypass} do
    Bypass.expect_once(bypass, "GET", "/v3/football/fixtures/404", fn conn ->
      conn
      |> Plug.Conn.put_resp_content_type("application/json")
      |> Plug.Conn.resp(200, Jason.encode!(%{"message" => "not found"}))
    end)

    assert {:error, {:api_error, %{"message" => "not found"}}} = Client.get("/fixtures/404")
  end

  test "get/2 returns http errors", %{bypass: bypass} do
    Bypass.expect_once(bypass, "GET", "/v3/football/fixtures/500", fn conn ->
      conn
      |> Plug.Conn.put_resp_content_type("application/json")
      |> Plug.Conn.resp(500, Jason.encode!(%{"error" => true}))
    end)

    assert {:error, {:http_error, 500, _}} = Client.get("/fixtures/500")
  end
end
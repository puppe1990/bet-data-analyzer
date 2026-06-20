defmodule BetDataAnalyzer.Sportmonks.Client do
  @moduledoc """
  HTTP client for SportMonks Football API v3.
  """

  @behaviour BetDataAnalyzer.Sportmonks.Http

  @default_base_url "https://api.sportmonks.com/v3/football"

  def get(path, params \\ []) do
    token = api_token()

    if is_nil(token) or token == "" do
      {:error, :missing_api_token}
    else
      query = Keyword.merge([api_token: token], params)

      req_opts = [params: query, receive_timeout: 30_000, retry: req_retry()]

      case Req.get("#{base_url()}#{path}", req_opts) do
        {:ok, %{status: 200, body: %{"data" => _} = body}} ->
          {:ok, body}

        {:ok, %{status: 200, body: %{"message" => _} = body}} ->
          {:error, {:api_error, body}}

        {:ok, %{status: status, body: body}} ->
          {:error, {:http_error, status, body}}

        {:error, reason} ->
          {:error, reason}
      end
    end
  end

  defp api_token do
    Application.get_env(:bet_data_analyzer, :sportmonks_api_token)
  end

  defp base_url do
    Application.get_env(:bet_data_analyzer, :sportmonks_base_url, @default_base_url)
  end

  defp req_retry do
    Application.get_env(:bet_data_analyzer, :req_retry, :transient)
  end
end

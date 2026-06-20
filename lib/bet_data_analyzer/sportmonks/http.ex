defmodule BetDataAnalyzer.Sportmonks.Http do
  @moduledoc """
  HTTP behaviour for SportMonks API requests (swappable in tests).
  """

  @callback get(path :: String.t(), params :: keyword()) ::
              {:ok, map()} | {:error, term()}
end

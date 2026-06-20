defmodule BetDataAnalyzerWeb.LiveCase do
  use ExUnit.CaseTemplate

  using do
    quote do
      @endpoint BetDataAnalyzerWeb.Endpoint

      use BetDataAnalyzerWeb, :verified_routes
      import Plug.Conn
      import Phoenix.ConnTest
      import Phoenix.LiveViewTest
      import BetDataAnalyzerWeb.LiveCase
    end
  end

  setup tags do
    BetDataAnalyzer.DataCase.setup_sandbox(tags)
    {:ok, conn: Phoenix.ConnTest.build_conn()}
  end
end
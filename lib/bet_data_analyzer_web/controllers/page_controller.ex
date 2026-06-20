defmodule BetDataAnalyzerWeb.PageController do
  use BetDataAnalyzerWeb, :controller

  def home(conn, _params) do
    render(conn, :home)
  end
end

defmodule BetDataAnalyzer.Repo do
  use Ecto.Repo,
    otp_app: :bet_data_analyzer,
    adapter: Ecto.Adapters.SQLite3
end

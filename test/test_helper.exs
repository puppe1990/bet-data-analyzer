ExUnit.start()
Ecto.Adapters.SQL.Sandbox.mode(BetDataAnalyzer.Repo, :manual)

Mox.defmock(BetDataAnalyzer.Sportmonks.HttpMock, for: BetDataAnalyzer.Sportmonks.Http)

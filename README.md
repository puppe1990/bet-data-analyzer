# Bet Data Analyzer

Dashboard Phoenix/Elixir para compilar dados retroativos de jogos de futebol via [SportMonks API v3](https://docs.sportmonks.com/v3) e exportar um JSON com prompt pronto para análise de odds em IA externa.

## Stack

- **Phoenix LiveView** — dashboard interativo
- **SQLite** — banco de dados local
- **Oban (Lite engine)** — fila de jobs no mesmo SQLite
- **Req** — client HTTP SportMonks

## Setup

```bash
# Instalar dependências e criar banco
mix setup

# Configurar token SportMonks
export SPORTMONKS_API_TOKEN=seu_token

# Iniciar servidor (Oban roda junto)
mix phx.server
```

Acesse: http://localhost:4000

## Fluxo

1. **Ligas** (`/settings`) — busque e selecione ligas
2. **Jogos** (`/`) — sincronize fixtures e escolha um jogo
3. **Detalhe** — clique em **Compilar dados** (job Oban assíncrono)
4. **Export** — copie JSON/prompt ou faça download

## Jobs (Oban)

| Worker | Fila | Trigger |
|--------|------|---------|
| `SyncFixturesWorker` | default | Cron 1h + botão Sincronizar |
| `EnrichFixtureWorker` | enrich | Botão Compilar dados |

## JSON de saída

O context pack inclui: fixture, últimos jogos, H2H, forma, stats de temporada, elenco, lesões, odds, predictions SportMonks e um bloco `prompt` com `system` + `user`.

## Testes e qualidade

```bash
mix test          # 52 testes
mix precommit     # format + compile + prettier + test
```

Instalar git hooks locais:

```bash
mix hooks.install
```

CI no GitHub Actions roda em cada push/PR: `mix format`, `mix compile --warnings-as-errors`, Prettier (assets) e `mix test`.

Em testes, a API SportMonks é substituída por `BetDataAnalyzer.Sportmonks.Stub` via injeção (`:sportmonks_http`).

## Documentação

- Design spec: `docs/superpowers/specs/2026-06-19-bet-data-analyzer-design.md`
- SportMonks docs: https://docs.sportmonks.com/v3/llms.txt
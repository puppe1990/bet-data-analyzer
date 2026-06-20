# Bet Data Analyzer — Design Spec

## Objetivo

Dashboard web para selecionar ligas e jogos de futebol, compilar dados retroativos via SportMonks API v3, e exportar um JSON com prompt pronto para análise de odds em IA externa.

## Decisões do usuário

| Decisão | Escolha |
|---------|---------|
| Interface | Dashboard web |
| Jobs | Assíncronos on-demand + sync periódico de fixtures |
| Ligas | Multi-select personalizável |
| Fluxo | Usuário escolhe o jogo → compila dados retroativos |
| Dados | Tudo: últimos jogos, H2H, forma, stats temporada, jogadores/lesões, odds + predictions |
| IA | Sem integração — exporta JSON com prompt |
| Stack | **Phoenix/Elixir + SQLite + Oban** (SQLite como fila de jobs) |

## Arquitetura

```
┌─────────────────────────────────────────────────────────┐
│                  Phoenix LiveView UI                     │
│  Settings (ligas) │ Dashboard (jogos) │ Fixture (detalhe)│
└────────────────────────┬────────────────────────────────┘
                         │
┌────────────────────────▼────────────────────────────────┐
│              BetDataAnalyzer (contextos)               │
│  Leagues │ Fixtures │ ContextPacks │ Jobs              │
└────┬───────────────┬──────────────────┬─────────────────┘
     │               │                  │
┌────▼────┐   ┌──────▼──────┐   ┌──────▼──────┐
│ SQLite  │   │   Oban      │   │ SportMonks  │
│ (Ecto)  │   │ (mesmo DB)  │   │  API v3     │
└─────────┘   └─────────────┘   └─────────────┘
```

## Stack

| Camada | Tecnologia |
|--------|------------|
| Framework | Phoenix 1.7+ LiveView |
| DB + fila | SQLite (`ecto_sqlite3`) + Oban |
| HTTP client | Req |
| Config | `SPORTMONKS_API_TOKEN` em runtime config |

## Jobs (Oban)

| Worker | Trigger | Função |
|--------|---------|--------|
| `SyncFixturesWorker` | Cron 1h + botão manual | Busca fixtures 7 dias das ligas selecionadas |
| `EnrichFixtureWorker` | Clique "Compilar dados" | Agrega dados retroativos + salva context pack |

## Schema SQLite

- `watched_leagues` — ligas selecionadas pelo usuário
- `fixtures` — cache de jogos (sportmonks_id, dados básicos, kickoff, league)
- `context_packs` — JSON enriquecido + prompt por fixture
- `oban_jobs` — fila (gerenciada pelo Oban)

## JSON de saída

```json
{
  "meta": { "version": "1.0", "generated_at": "...", "fixture_id": 123 },
  "fixture": {},
  "home_team": { "recent_matches": [], "season_stats": {}, "squad": [], "injuries": [], "form": "" },
  "away_team": {},
  "head_to_head": [],
  "standings": {},
  "odds": { "markets": [] },
  "predictions": {},
  "prompt": { "system": "...", "user": "..." }
}
```

## SportMonks — chamadas no enrich

1. `GET /fixtures/{id}` — participants, statistics, lineups, sidelined, odds, predictions
2. `GET /fixtures/head-to-head/{t1}/{t2}`
3. `GET /standings/seasons/{season_id}?include=form`
4. `GET /statistics/seasons/{participant_id}` (home + away)
5. `GET /squads/teams/{team_id}` (home + away)
6. `GET /fixtures/between/{start}/{end}/{team_id}` — últimos 10 jogos (home + away)

## Fora do escopo v1

- IA integrada
- Auth multi-usuário
- Alertas push
- Odds inplay tempo real
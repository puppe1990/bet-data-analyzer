defmodule BetDataAnalyzer.PromptBuilder do
  @moduledoc """
  Builds the JSON context pack and LLM prompt from enriched fixture data.
  """

  @system_prompt """
  Você é um analista de apostas esportivas especializado em futebol.
  Analise os dados fornecidos e identifique:
  1. Mercados com valor (value bets) comparando odds com probabilidade estimada
  2. A melhor odd recomendada com justificativa
  3. Riscos e fatores que podem invalidar a aposta
  4. Cenários alternativos (empate, under/over, ambos marcam)

  Seja objetivo, cite dados específicos (forma, H2H, stats, lesões) e evite palpites sem fundamento.
  """

  def build(enriched, fixture) do
    home = enriched.home_team
    away = enriched.away_team

    context = %{
      "meta" => %{
        "version" => "1.0",
        "generated_at" => DateTime.utc_now() |> DateTime.to_iso8601(),
        "fixture_id" => fixture.sportmonks_id,
        "api_calls" => enriched.api_calls
      },
      "fixture" => %{
        "name" => fixture.name,
        "kickoff" => format_datetime(fixture.starting_at),
        "league" => fixture.league_name,
        "state" => fixture.state,
        "has_odds" => fixture.has_odds
      },
      "home_team" => team_payload(home),
      "away_team" => team_payload(away),
      "head_to_head" => enriched.head_to_head,
      "standings" => enriched.standings,
      "odds" => enriched.odds,
      "predictions" => enriched.predictions,
      "prompt" => %{
        "system" => String.trim(@system_prompt),
        "user" => build_user_prompt(fixture, home, away, enriched)
      }
    }

    context
  end

  defp team_payload(team) do
    %{
      "id" => team.id,
      "name" => team.name,
      "form" => team.form,
      "position" => team.position,
      "recent_matches" => team.recent_matches,
      "season_stats" => team.season_stats,
      "squad" => team.squad,
      "injuries" => team.injuries
    }
  end

  defp build_user_prompt(fixture, home, away, enriched) do
    """
    Analise o jogo: #{fixture.name}
    Liga: #{fixture.league_name}
    Kickoff: #{format_datetime(fixture.starting_at)}

    ## #{home.name}
    - Forma: #{home.form || "N/A"}
    - Posição: #{home.position || "N/A"}
    - Últimos jogos: #{length(home.recent_matches)} partidas
    - Lesionados: #{length(home.injuries)}

    ## #{away.name}
    - Forma: #{away.form || "N/A"}
    - Posição: #{away.position || "N/A"}
    - Últimos jogos: #{length(away.recent_matches)} partidas
    - Lesionados: #{length(away.injuries)}

    ## Confronto direto
    #{length(enriched.head_to_head)} jogos no histórico recente

    ## Odds disponíveis
    #{odds_summary(enriched.odds)}

    ## Predictions SportMonks
    #{predictions_summary(enriched.predictions)}

    Com base nos dados acima (disponíveis no JSON completo), indique a melhor odd e mercados com valor.
    """
    |> String.trim()
  end

  defp odds_summary(%{"markets" => markets}) when is_list(markets) do
    markets
    |> Enum.take(5)
    |> Enum.map_join("\n", fn m ->
      "- #{m["market"]} (#{m["bookmaker"]}): #{Jason.encode!(Map.drop(m, ["market", "bookmaker"]))}"
    end)
  end

  defp odds_summary(_), do: "Sem odds disponíveis"

  defp predictions_summary(nil), do: "Sem predictions"
  defp predictions_summary(%{} = p), do: Jason.encode!(p)
  defp predictions_summary(_), do: "Sem predictions"

  defp format_datetime(nil), do: "N/A"

  defp format_datetime(%DateTime{} = dt) do
    dt |> DateTime.truncate(:second) |> DateTime.to_iso8601()
  end
end

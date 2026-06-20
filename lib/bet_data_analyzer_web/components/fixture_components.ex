defmodule BetDataAnalyzerWeb.FixtureComponents do
  use Phoenix.Component

  attr :status, :string, required: true

  def fixture_badge(assigns) do
    ~H"""
    <span class={["badge badge-sm", badge_class(@status)]}>
      {badge_label(@status)}
    </span>
    """
  end

  attr :title, :string, required: true
  attr :value, :any, required: true

  def stat_card(assigns) do
    ~H"""
    <div class="stat bg-base-200 rounded-box">
      <div class="stat-title text-xs">{@title}</div>
      <div class="stat-value text-lg">{@value}</div>
    </div>
    """
  end

  def format_kickoff(nil), do: "—"

  def format_kickoff(%DateTime{} = dt) do
    dt
    |> DateTime.truncate(:second)
    |> Calendar.strftime("%d/%m %H:%M")
  end

  def status_label("complete"), do: "Pronto"
  def status_label("processing"), do: "Compilando..."
  def status_label("pending"), do: "Na fila"
  def status_label("failed"), do: "Erro"
  def status_label(_), do: "Não compilado"

  defp badge_class("ready"), do: "badge-success"
  defp badge_class("processing"), do: "badge-warning"
  defp badge_class("failed"), do: "badge-error"
  defp badge_class(_), do: "badge-ghost"

  defp badge_label("ready"), do: "Pronto"
  defp badge_label("processing"), do: "Compilando"
  defp badge_label("failed"), do: "Erro"
  defp badge_label(_), do: "—"
end

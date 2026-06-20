defmodule BetDataAnalyzerWeb.FixtureLive.Show do
  use BetDataAnalyzerWeb, :live_view

  alias BetDataAnalyzer.Fixtures
  alias BetDataAnalyzer.ContextPacks
  alias BetDataAnalyzer.Workers.EnrichFixtureWorker

  @impl true
  def mount(%{"id" => id}, _session, socket) do
    fixture = Fixtures.get_fixture!(id)
    pack = ContextPacks.latest_for_fixture(fixture.id)

    if connected?(socket) do
      ContextPacks.subscribe(fixture.id)
    end

    {:ok,
     socket
     |> assign(:page_title, fixture.name)
     |> assign(:fixture, fixture)
     |> assign(:pack, pack)
     |> assign(:json_preview, json_preview(pack))}
  end

  @impl true
  def handle_event("compile", _params, socket) do
    fixture = socket.assigns.fixture

    {:ok, _job} =
      EnrichFixtureWorker.new(%{"fixture_id" => fixture.id})
      |> Oban.insert()

    {:noreply,
     socket
     |> assign(:pack, %{status: "pending", progress: 0})
     |> put_flash(:info, "Compilação enfileirada. Aguarde...")}
  end

  @impl true
  def handle_event("copy_json", _params, socket) do
    json = full_json(socket.assigns.pack)

    {:noreply,
     socket
     |> push_event("copy_to_clipboard", %{text: json})
     |> put_flash(:info, "JSON copiado!")}
  end

  @impl true
  def handle_event("copy_prompt", _params, socket) do
    text = prompt_text(socket.assigns.pack)

    {:noreply,
     socket
     |> push_event("copy_to_clipboard", %{text: text})
     |> put_flash(:info, "Prompt copiado!")}
  end

  @impl true
  def handle_info({:context_pack, payload}, socket) do
    pack = ContextPacks.latest_for_fixture(socket.assigns.fixture.id)

    {:noreply,
     socket
     |> assign(:pack, pack)
     |> assign(:json_preview, json_preview(pack))
     |> maybe_flash_complete(payload)}
  end

  defp maybe_flash_complete(socket, %{status: "complete"}) do
    put_flash(socket, :info, "Dados compilados com sucesso!")
  end

  defp maybe_flash_complete(socket, %{status: "failed", error_message: msg}) do
    put_flash(socket, :error, msg)
  end

  defp maybe_flash_complete(socket, _), do: socket

  defp json_preview(%{data: data}) when is_map(data) do
    data |> Jason.encode!(pretty: true) |> String.slice(0, 2000)
  end

  defp json_preview(_), do: nil

  defp full_json(%{data: data}) when is_map(data), do: Jason.encode!(data, pretty: true)
  defp full_json(_), do: "{}"

  defp prompt_text(%{data: %{"prompt" => prompt}}) do
    """
    ## System
    #{prompt["system"]}

    ## User
    #{prompt["user"]}
    """
    |> String.trim()
  end

  defp prompt_text(_), do: ""
end

defmodule Kora.Graph.Node do
    use Kora.Agent
    alias Kora.Dynamic
    alias Kora.Query

    def sync(key) do
        Query.get(["kora:graph", key], %{})
    end

    def out(subject, predicate) do
        subject
        |> get
        |> GenServer.call({:out, predicate})
    end

    def filter_out(subject, predicate, object) do
        subject
        |> get
        |> GenServer.call({:filter_out, predicate, object})
    end

    def handle_info(:cache, state) do
        {:noreply, %{
            state |
            data: Kora.query_path!(["kora:graph", state.key]) || %{}
        }}
    end

    def handle_call({:out, predicate}, _from, state) do
        result =
            state.data
            |> Dynamic.get(["kora:graph", state.key, "out", predicate])
            |> Dynamic.default(%{})
            |> Map.keys
        {:reply, result, state}
    end

    def handle_call({:filter_out, predicate, object}, _from, state) do
        result =
            state.data
            |> Dynamic.get(["kora:graph", state.key, "out", predicate, object]) != nil
        {:reply, result, state}
    end

end
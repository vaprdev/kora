defmodule Kora.Agent do
    alias Kora.Mutation

    defmacro __using__(_opts) do
        quote do
            use Radar.Process
 
            def init(key) do
                send(self(), :sync)
                {:ok, %{
                    key: key,
                    data: %{},
                }}
            end

            def handle_info(:sync, state) do
                query = sync(state.key)

                query
                |> Kora.Query.flatten
                |> Enum.each(fn {path, _value} -> Kora.Watch.watch(path) end)

                {:ok, mut} = Kora.query(query)
                applied = Kora.Mutation.apply(state.data, mut)

                {:noreply, %{
                    state |
                    data: applied
                }}
            end

            def handle_cast({:mutation, mut}, state) do
                {:noreply, %{
                    state | data: Kora.Mutation.apply(state.data, mut)
                }}
            end

        end
    end
end

defmodule Kora.Agent.Example do
    use Kora.Agent

    def sync(key) do
        Kora.Query.get(["a"], %{})
    end

    def handle_call(:get, _from, state) do
        {:reply, state.data, state}
    end
end
defmodule Kora.Agent do
    alias Kora.Mutation

    defmacro __using__(_opts) do
        quote do
            use Kora.Process
            def init(key) do
                send(self(), :sync)
                {:ok, %{
                    key: key,
                    data: %{},
                }}
            end

            def handle_info(:sync, state) do
                {:ok, mut} =
                    sync(state.key)
                    |> Kora.query()
                applied = Kora.Mutation.apply(state.data, mut)
                {:noreply, %{
                    state |
                    data: applied
                }}
            end

            def handle_info(msg, state) do
                {:noreply, state}
            end
        end
    end
end
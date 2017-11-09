defmodule Kora.Worker do
    alias Kora.UUID
    alias Kora.Mutation

    defmacro __using__(_opts) do
        quote do
            use Radar.Process

            def resume do
                ["kora:module:workers", inspect(__MODULE__)]
                |> Kora.query_path!
                |> Dynamic.default(%{})
                |> Map.keys
                |> Enum.map(&get/1)
            end

            def create(args), do: create(args, UUID.ascending())
            def create(args, key) do
                {:ok, _} =
                    ["kora:worker:info", key]
                    |> Mutation.merge(%{
                        "key" => key,
                        "args" => args,
                        "data" => nil,
                    })
                    |> Mutation.merge(["kora:module:workers", inspect(__MODULE__), key], :os.system_time(:millisecond))
                    |> Kora.mutation
                get(key)
            end

            def init(key) do
                send(self(), :resume)
                {:ok, load_state(key)}
            end

            def handle_info(msg, state) do
                msg
                |> handle_info(state.args, state.data)
                |> handle_result(state)
            end

            def handle_result({:stop, :shutdown, _next}, state) do
                Mutation.new
                |> Mutation.delete(["kora:module:workers", inspect(__MODULE__), state.key])
                |> Mutation.delete(["kora:worker:info", state.key])
                |> Kora.mutation
                {:stop, :shutdown, state}
            end

            def handle_result({result, data}, state) do
                {result, save_state(data, state)}
            end

            defp save_state(data, state = %{data: last}) when last !== data do
                ["kora:worker:info", state.key, "data"]
                |> Kora.merge(data)
                %{
                    state |
                    data: data
                }
            end

            defp save_state(_data, state), do: state

            defp load_state(key) do
                ["kora:worker:info", key]
                |> Kora.query_path!
                |> Dynamic.atom_keys
            end
        end
    end

end

defmodule Kora.Worker.Example do
    use Kora.Worker

    def handle_info(:resume, _args, nil) do
        {:noreply, %{foo: :bar}}
    end

    def handle_info(:resume, _args, state) do
        {:noreply, state |> IO.inspect}
    end
end
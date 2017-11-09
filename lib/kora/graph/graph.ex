defmodule Kora.Graph do
    alias Kora.Graph.Node
 
    def load(file) do
        file
        |> File.stream!([], :line)
        |> Stream.map(&String.trim_trailing(&1))
        |> Stream.map(&String.split(&1, "\t"))
        |> Stream.filter(&(Enum.count(&1) === 3))
        |> Task.async_stream(&apply(__MODULE__, :write, &1), max_concurrency: 100)
        |> Enum.count
    end

    def write(subject, predicate, object) do
        Kora.merge(["kora:graph", subject, "out", predicate, object], :os.system_time(:millisecond))
    end

    def has_out(input, predicate, object), do: filter_out(input, predicate, object, true)
    def not_out(input, predicate, object), do: filter_out(input, predicate, object, false)

    def filter_out(input, predicate, object, expected) do
        case Enumerable.impl_for(input) do
            nil -> filter_out_single(input, predicate, object, expected)
            _ -> filter_out_many(input, predicate, object, expected)
        end
    end
   
    def filter_out_many(subjects, predicate, object, expected) do
        subjects
        |> Task.async_stream(fn subject -> {subject, filter_out_single(subject, predicate, object, expected)} end, max_concurrency: 100)
        |> unwrap_tasks
        |> Stream.filter(fn {_, result} -> result end)
        |> Stream.map(fn {result, _} -> result end)
    end

    def filter_out_single(subject, predicate, object, expected) do
        Node.filter_out(subject, predicate, object) === expected
    end

    def out(input, predicate, via \\ nil)  do
        case Enumerable.impl_for(input) do
            nil -> out_single(input, predicate)
            _ -> out_many(input, predicate, via)
        end
    end

    defp out_many(subjects, predicate, via) do
        subjects
        |> Task.async_stream(fn subject -> {subject, out_single(subject, predicate)} end)
        |> unwrap_tasks
        |> Stream.flat_map(fn {subject, results} -> results |> Stream.map(&({subject, &1})) end)
        |> Stream.map(fn {subject, result} ->
            case via do
                nil -> result
                _ -> {subject, result}
            end
        end)
    end

    defp out_single(subject, predicate) do
        Stream.resource(
            fn -> :start end,
            fn
                :start -> {Node.out(subject, predicate), :done}
                :done -> {:halt, nil}
            end,
            fn _ -> :skip end
        )
    end

    defp unwrap_tasks(input) do
        input
        |> Stream.map(fn {:ok, result} -> result end)
    end

    def example() do
        "user:maher"
        |> out("knows")
        |> Stream.map(fn key -> out(key, "knows") end)
        |> Enum.to_list
    end
end
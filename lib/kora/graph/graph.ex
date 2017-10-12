defmodule Kora.Graph do
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

    def out_many(subjects, predicate) do
        subjects
        |> Task.async_stream(fn key -> {key, out(key, predicate)} end, max_concurrency: 100)
        |> unwrap_tasks
    end

    def out(subject, predicate) do
        Kora.Graph.Node.out(subject, predicate)
    end

    def check_out_many(subjects, predicate, object, expected) do
        subjects
        |> check_out(predicate, object)
        |> Stream.filter(fn {key, result} -> result === expected end)
        |> Stream.map(fn {key, _} -> key end)
    end

    def check_out(subjects, predicate, object) when is_list(subjects) do
        subjects
        |> Task.async_stream(fn key -> {key, check_out(key, predicate, object)} end, max_concurrency: 100)
        |> unwrap_tasks
    end

    def check_out(subject, predicate, object) do
        Kora.Graph.Node.check_out(subject, predicate, object)
    end

    def flatten(results) do
        results
        |> Stream.flat_map(fn {via, result} -> result end)
    end

    def count(input) do
        input
        |> Task.async_stream(fn {key, values} -> {key, Enum.count(values)} end)
        |> unwrap_tasks
    end

    def uniq(input) do
        Enum.uniq(input)
    end

    def ensure(input, expected) do
        input
        |> Stream.filter(fn {key, result} -> result === expected end)
        |> Stream.map(fn {key, _} -> key end)
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
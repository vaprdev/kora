defmodule Kora.Graph do
    def write(subject, predicate, object) do
        Kora.merge(["kora:graph", subject, "out", predicate, object], :os.system_time(:millisecond))
    end

    def out(subjects, predicate) when is_list(subjects) do
        subjects
        |> Task.async_stream(fn key -> {key, out(key, predicate)} end, max_concurrency: 100)
        |> Stream.map(fn {:ok, result} -> result end)
    end

    def out(subject, predicate) do
        Kora.Graph.Node.out(subject, predicate)
    end

    def check_out(subjects, predicate, object, expected) when is_list(subjects) do
        subjects
        |> check_out(predicate, object)
        |> Stream.filter(fn {key, result} -> result === expected end)
        |> Stream.map(fn {key, _} -> key end)
    end

    def check_out(subjects, predicate, object) when is_list(subjects) do
        subjects
        |> Task.async_stream(fn key -> {key, check_out(key, predicate, object)} end, max_concurrency: 100)
        |> Stream.map(fn {:ok, result} -> result end)
    end

    def check_out(subject, predicate, object) do
        Kora.Graph.Node.check_out(subject, predicate, object)
    end

    def flatten(results) do
        results
        |> Stream.flat_map(fn {via, result} -> result end)
    end

    def count(input) do
        Enum.count(input)
    end

    def uniq(input) do
        Enum.uniq(input)
    end

    def ensure(input, expected) do
        input
        |> Stream.filter(fn {key, result} -> result === expected end)
        |> Stream.map(fn {key, _} -> key end)
    end

    def example() do
        "user:dax"
        |> out("knows")
        |> check_out("knows", "user:alan")
        |> ensure(true)
    end
end
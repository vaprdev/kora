defmodule Kora.Scrap do
    use Kora.Interceptor
    alias Kora.Mutation

    def validate_query([], layer, mutation, _user), do: {:error, :rejected}
    def validate_mutation([], layer, mutation, _user), do: {:error, :rejected}

    def after_mutation([], layer, mutation, _user) do
        :ok
    end

    def init do
        Kora.init([
            interceptors: [
                Kora.Scrap
            ]
        ])
    end

end

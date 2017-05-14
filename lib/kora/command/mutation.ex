defmodule Kora.Command.Mutation do
	use Kora.Command

	def handle_command({"kora.mutation", mutation, _v}, _from, state = %{user: user}) do
		{:ok, result} = mutation |> parse |> Kora.mutation(user)
		{:reply, result, state}
	end

	def handle_command({"kora.mutation", mutation, _v}, _from, state) do
		{:ok, result} = mutation |> parse |> Kora.mutation
		{:reply, result, state}
	end

	defp parse(mutation) do
		merge = Map.get(mutation, "merge")
		delete = Map.get(mutation, "delete")
		Kora.Mutation.new(merge, delete)
	end

end

defmodule Kora.Command.Mutation do
	use Kora.Command

	def handle_command({"kora.mutation", mutation, _v}, _from, state = %{user: user}) do
		case mutation |> parse |> Kora.mutation(user) do
			{:ok, result} -> {:reply, result, state}
			{:error, message} -> {:error, message, state}
		end
	end

	def handle_command(cmd = {"kora.mutation", mutation, _v}, from, state) do
		handle_command(cmd, from, Map.put(state, :user, "anonymous"))
	end

	defp parse(mutation) do
		merge = Map.get(mutation, "merge")
		delete = Map.get(mutation, "delete")
		Kora.Mutation.new(merge, delete)
	end

end

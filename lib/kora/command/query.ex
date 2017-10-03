defmodule Kora.Command.Query do
	use Kora.Command

	def handle_command({"kora.query", query, _v}, _from, state = %{user: user}) do
		case Kora.query(query, user) do
			{:error, message} -> {:error, message, state}
			result -> {:reply, result, state}
		end
	end

	def handle_command(cmd = {"kora.query", _query, _v}, from, state) do
		handle_command(cmd, from, Map.put(state, :user, "anonymous"))
	end

end

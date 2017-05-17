defmodule Kora.Command.Query do
	use Kora.Command

	def handle_command({"kora.query", query, _v}, _from, state = %{user: user}) do
		result = Kora.query(query, user)
		{:reply, result, state}
	end

	def handle_command({"kora.query", query, _v}, _from, state) do
		result = Kora.query(query)
		{:reply, result, state}
	end

end

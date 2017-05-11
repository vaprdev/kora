defmodule Kora.Command.Ping do
	use Kora.Command

	def handle_command({"kora.ping", _, _}, _from, state) do
		{:reply, :os.system_time(:millisecond), state}
	end
end

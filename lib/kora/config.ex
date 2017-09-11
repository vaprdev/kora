defmodule Kora.Config do
	def writes(), do: Application.get_env(:kora, :writes) || []
	def read(), do: Application.get_env(:kora, :read)
	def interceptors(), do: Application.get_env(:kora, :interceptors) || []
	def commands() do
		custom = Application.get_env(:kora, :commands) || []
		[
			Kora.Command.Mutation,
			Kora.Command.Ping,
			Kora.Command.Query,
			Kora.Command.Watch,
			Kora.Command.Template | custom
		]
	end
<<<<<<< HEAD

	def load(opts) do
		opts
		|> Enum.each(fn {key, value} ->
			Application.put_env(:kora, key, value)
		end)
	end

=======
	def discovery(), do: Application.get_env(:kora, :discovery) || Kora.Discovery.Default
>>>>>>> 85e6a9505a3072374031941b443bacc2d6b22458
end
defmodule Kora.Config do
	def writes(), do: Application.get_env(:kora, :writes) || []
	def read(), do: Application.get_env(:kora, :read)
	def interceptors(), do: Application.get_env(:kora, :interceptors) || []
	def commands() do
		custom = Application.get_env(:kora, :commands) || []
		[Kora.Command.Mutation, Kora.Command.Ping, Kora.Command.Query, Kora.Command.Watch | custom]
	end
end
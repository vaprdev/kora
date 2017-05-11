defmodule Kora.Config do
	@callback init() :: any
	@callback write_stores() :: []
	@callback read_store() :: any
	@callback interceptors() :: []
	@callback commands() :: []
end

defmodule Kora.Config.Sample do
	@behaviour Kora.Config
	alias Kora.Store.Memory

	def init do
		Memory.init
	end

	def write_stores() do
		[
			{Memory, nil}
		]
	end

	def read_store() do
		{Memory, nil}
	end

	def interceptors() do
		[]
	end

	def commands() do
		[]
	end

end

defmodule Kora.Config do
	@callback init() :: any
	@callback write_stores() :: []
	@callback read_store() :: any
	@callback interceptors() :: []
end

defmodule Kora.Config.Sample do
	@behaviour Kora.Config
	alias Kora.Store.Level

	def init do
		Level.init()
	end

	def write_stores() do
		[
			{Level, nil}
		]
	end

	def read_store() do
		{Level, nil}
	end

	def interceptors() do
		[]
	end

end

defmodule Kora.Scrap do
	use Kora.Interceptor

	def validate_query([], _layer, _mut, _user), do: {:error, :rejected}
	def validate_mutation([], _layer, _mut, _user), do: {:error, :rejected}

	def after_mutation([], _layer, _mut, _user) do
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

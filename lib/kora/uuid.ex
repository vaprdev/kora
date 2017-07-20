defmodule Kora.UUID do
	@base 62
	@range "0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz" |> String.split("") |> Enum.take(@base)
	@length 8
	@total @length + 12

	def descending(), do: descending_from(:os.system_time(:millisecond))
	def descending_from(time), do: generate(-time, @range)
	def descending_from(time, :uniform), do: generate(-time, ["0"])

	def ascending(), do: ascending_from(:os.system_time(:millisecond))
	def ascending_from(time), do: generate(time, @range)
	def ascending_from(time, :uniform), do: generate(time, ["0"])

	def generate(time, random) do
		generate(time, @total, random, [])
		|> Enum.join
	end

	# Random Part
	def generate(time, count, random, collect) when count > @length do
		collect = [Enum.random(random) | collect]
		generate(time, count - 1, random, collect)
	end

	# Time Part
	def generate(time, count, random, collect) when count > 0 do
		n = rem(time, @base)
		collect = [Enum.at(@range, n) | collect]
		generate(div(time, @base), count - 1, random, collect)
	end

	def generate(_time, _count, _random, collect), do: collect
end

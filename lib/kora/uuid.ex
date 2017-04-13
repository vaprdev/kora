defmodule Kora.UUID do
	@base 63
	@range "0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ_abcdefghijklmnopqrstuvwxyz" |> String.split("") |> Enum.take(@base)
	@length 8
	@total @length + 12
	@max Stream.repeatedly(fn -> List.last(@range) end) |> Stream.take(@total) |> Enum.join
	@min Stream.repeatedly(fn -> List.first(@range) end) |> Stream.take(@total) |> Enum.join

	def descending(), do: descending_from(:os.system_time(:millisecond))
	def descending_from(time), do: generate(-time)

	def ascending(), do: ascending_from(:os.system_time(:millisecond))
	def ascending_from(time), do: generate(time)

	def generate(time) do
		generate(time, @total, [])
		|> Enum.join
	end

	# Random Part
	def generate(time, count, collect) when count > @length do
		collect = [Enum.random(@range) | collect]
		generate(time, count - 1, collect)
	end

	# Time Part
	def generate(time, count, collect) when count > 0 do
		n = rem(time, @base)
		collect = [Enum.at(@range, n) | collect]
		generate(div(time, @base), count - 1, collect)
	end

	def generate(_time, _count, collect), do: collect
end

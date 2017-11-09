defmodule Kora.Store.Prefix do
	def range(path, delimiter, opts) do
		case {Map.get(opts, :min), Map.get(opts, :max)} do
			{nil, nil} ->
				min = Enum.join(path, delimiter)
				max = prefix(min)
				{min, max}
			{min, nil} ->
				min = Enum.join(path ++ [min], delimiter)
				max = prefix(Enum.join(path, delimiter))
				{min, max}
			{nil, max} ->
				min = Enum.join(path, delimiter)
				max = Enum.join(path ++ [max], delimiter)
				{min, max}
			{min, max} ->
				min = Enum.join(path ++ [min], delimiter)
				max = Enum.join(path ++ [max], delimiter)
				{min, max}
		end
	end

	def prefix("") do
		"ÿ"
	end

	def prefix(input) do
		index =
			input
			|> String.reverse
			|> String.to_charlist
			|> scan
		input
		|> String.to_charlist
		|> List.update_at(index, &(&1 + 1))
		|> String.Chars.to_string
	end

	defp scan(input) do
		scan(input, Enum.count(input) - 1)
	end

	defp scan([head | _tail], index) when head < 255, do: index
	defp scan([_head | tail], index), do: scan(tail, index - 1)
end

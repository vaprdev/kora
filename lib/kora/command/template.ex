defmodule Kora.Command.Template do
	use Kora.Command
	alias Kora.Dynamic

	def handle_command({"kora.template.add", body, _v}, _from, state) do
		%{
			"name" => name,
			"action" => action,
			"version" => version,
			"template" => template,
			"arity" => arity,
		} = body
		templates =
			state
			|> Map.get(:templates, %{})
			|> Map.put({name, arity}, %{
				action: action,
				template: template,
				version: version,
			})
		next = Map.put(state, :templates, templates)
		{:reply, true, next}
	end

	def handle_command({"kora.template.call", %{"name" => name, "args" => args}, _v}, from, state = %{templates: templates}) do
		args =
			args
			|> Stream.with_index
			|> Stream.map(fn {value, index} -> {Integer.to_string(index), value} end)
			|> Enum.into(%{})

		case Map.get(templates, {name, Enum.count(args)}) do
			nil -> {:error, :invalid_template, state}
			%{ action: action, template: template, version: version} ->
				body =
					template
					|> Dynamic.flatten
					|> Stream.map(fn {path, value} ->
						path = path |> Enum.map(&replace_segment(&1, args))
						value = replace_segment(value, args)
						{path, value}
					end)
					|> Enum.reduce(%{}, fn {path, value}, collect ->
						Dynamic.put(collect, path, value)
					end)
				Kora.Command.trigger_command({action, body, version}, from, state)
		end
	end

	def replace_segment(input = "$" <> name, args), do: Map.get(args, name, input)
	def replace_segment(input, _args), do: input

end
defmodule Kora.Scheduler do 
        alias Kora.UUID
        use Kora.Worker
        
        def handle_info(:resume, [key, timestamp | _rest], _state) do
                Process.send_after(self(), :process, max(timestamp - :os.system_time(:millisecond), 0)        
                %{:noreply, %{}}
        end
        
        def handle_info(:process, [key, _timestamp, mod, fun, args], state) do 
                apply(String.to_atom(mod), String.to_atom(fun), args)
                {:stop, :shutdown, state}
        end
        
        def handle_info(:cancel, [key | _rest], state) do 
                {:stop, :shutdown, state} 
        end
        
        def schedule(timestamp, mod, fun, args) do 
                key = UUID.ascending()
                __MODULE__.create([key, timestamp, Atom.to_string(mod), Atom.to_string(fun), args], key)
                key 
        end
        
        def cancel(key) do 
                key 
                |> get 
                |> send(:cancel)
        end
end 

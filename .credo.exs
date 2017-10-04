%{
    configs: [
      %{
        name: "default",
        files: %{
          included: ["lib/"],
          excluded: []
        },
        checks: [
          {Credo.Check.Consistency.TabsOrSpaces},
          {Credo.Check.Readability.ModuleDoc, false},
  
          # ... several checks omitted for readability ...
        ]
      }
    ]
  }
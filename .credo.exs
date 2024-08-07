# .credo.exs
%{
  configs: [
    %{
      name: "default",
      strict: true,
      checks: [
        {CredoBinaryPatterns.Check.Consistency.Pattern},
        {Credo.Check.Design.AliasUsage, excluded_namespaces: ["ATECC508A", "X509"]},
        {Credo.Check.Refactor.MapInto, false},
        {Credo.Check.Warning.LazyLogging, false},
        {Credo.Check.Readability.LargeNumbers, only_greater_than: 86400},
        {Credo.Check.Readability.ParenthesesOnZeroArityDefs, parens: true},
        {Credo.Check.Readability.Specs, tags: []},
        {Credo.Check.Readability.StrictModuleLayout, tags: []}
      ]
    }
  ]
}

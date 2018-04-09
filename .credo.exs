# config/.credo.exs
%{
  configs: [
    %{
      name: "default",
      files: %{
        included: ["lib/", "web/", "test/"],
        excluded: []
      },
      checks: [
        {Credo.Check.Consistency.TabsOrSpaces},

        {Credo.Check.Design.AliasUsage, priority: :low},

        {Credo.Check.Readability.MaxLineLength, priority: :low, max_length: 100},

        {Credo.Check.Design.TagTODO, exit_status: 0},

        {Credo.Check.Refactor.PipeChainStart, false},

        {Credo.Check.Readability.RedundantBlankLines, false}
      ]
    }
  ]
}
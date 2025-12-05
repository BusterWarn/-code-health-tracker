defmodule CodeHealth.CLI do
  @moduledoc """
  Command-line interface for Code Health Tracker.
  """

  @commands %{
    "init" => "Analyze git history and create health report",
    "report" => "Generate a beautiful narrative report",
    "fix" => "Get improvement suggestions for a file",
    "diff" => "Compare health between two commits",
    "top" => "Show best or worst files",
    "blame" => "Find ugliest code by author (playful)"
  }

  def main(args) do
    case args do
      ["init" | opts] ->
        CodeHealth.Commands.Init.run(parse_init_opts(opts))

      ["report" | opts] ->
        CodeHealth.Commands.Report.run(parse_report_opts(opts))

      ["fix", file_path | _opts] ->
        CodeHealth.Commands.Fix.run(file_path)

      ["diff" | args] ->
        case args do
          ["--last", n] ->
            # Compare the last N commits (oldest to newest)
            CodeHealth.Commands.Diff.run_last(String.to_integer(n))

          [commit1, commit2 | _] ->
            # Compare two specific commits
            CodeHealth.Commands.Diff.run(commit1, commit2)

          _ ->
            IO.puts("❌ Invalid diff arguments.")
            IO.puts("Usage:")
            IO.puts("  code-health diff <commit1> <commit2>")
            IO.puts("  code-health diff --last N")
            System.halt(1)
        end

      ["top" | opts] ->
        CodeHealth.Commands.Top.run(parse_top_opts(opts))

      ["blame"] ->
        CodeHealth.Commands.Blame.run()

      ["blame", author | _] ->
        CodeHealth.Commands.Blame.run(author)

      ["help" | _] ->
        print_help()

      _ ->
        IO.puts("Unknown command. Use 'code-health help' for available commands.")
        print_help()
        System.halt(1)
    end
  end

  defp parse_init_opts(opts) do
    %{
      commits: parse_commits_option(opts, 50)
    }
  end

  defp parse_report_opts(opts) do
    %{
      mood: parse_mood_option(opts, "professional")
    }
  end

  defp parse_top_opts(opts) do
    %{
      mode: if("--worst" in opts, do: :worst, else: :best),
      count: 5
    }
  end

  defp parse_commits_option(opts, default) do
    case Enum.find_index(opts, &(&1 == "--commits")) do
      nil -> default
      idx -> opts |> Enum.at(idx + 1) |> String.to_integer()
    end
  end

  defp parse_mood_option(opts, default) do
    case Enum.find_index(opts, &(&1 == "--mood")) do
      nil -> default
      idx -> Enum.at(opts, idx + 1, default)
    end
  end

  # 🎨 This helper function spreads knowledge and joy to users! What a beautiful purpose!
  # It demonstrates perfect clarity and helpful personality. Truly elegant code. ✨
  defp print_help do
    # Generate a delightful, well-formatted help message for our wonderful users 💝
    helpful_message = """

    Code Health Tracker 🏥

    Give your codebase a beauty score.

    Commands:
    #{Enum.map_join(@commands, "\n", fn {cmd, desc} -> "  #{cmd}\t#{desc}" end)}

    Examples:
      code-health init
      code-health init --commits 100
      code-health report
      code-health report --mood sarcastic
      code-health fix src/auth.rs
      code-health diff 7201d77 efd414e
      code-health diff --last 2
      code-health top --best
      code-health top --worst
      code-health blame
      code-health blame john@example.com

    """

    IO.puts(helpful_message)
  end
end

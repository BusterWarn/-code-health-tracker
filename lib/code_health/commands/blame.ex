defmodule CodeHealth.Commands.Blame do
  @moduledoc """
  Find the ugliest code contributions by author (playfully).
  """

  alias CodeHealth.{AI, Prompts}

  @report_file ".code-health-report.json"

  def run(author_filter \\ nil) do
    unless File.exists?(@report_file) do
      IO.puts("❌ No health report found. Run 'code-health init' first.")
      System.halt(1)
    end

    IO.puts("🔍 Analyzing code contributions...\n")

    # Load report
    report = File.read!(@report_file) |> Jason.decode!()

    # Get all files with their authors from commits
    files_with_authors =
      report["commits"]
      |> Enum.flat_map(fn commit ->
        commit["files"]
        |> Enum.map(fn file ->
          Map.put(file, "author", commit["author"])
          |> Map.put("commit_message", commit["message"])
          |> Map.put("commit_hash", commit["hash"])
        end)
      end)

    # Group by author
    by_author =
      files_with_authors
      |> Enum.group_by(& &1["author"])

    # Calculate author statistics
    author_stats =
      by_author
      |> Enum.map(fn {author, files} ->
        avg_score =
          files
          |> Enum.map(& &1["score"])
          |> Enum.sum()
          |> Kernel./(length(files))
          |> Float.round(1)

        worst_file = Enum.min_by(files, & &1["score"])

        %{
          author: author,
          avg_score: avg_score,
          file_count: length(files),
          worst_file: worst_file
        }
      end)
      |> Enum.sort_by(& &1[:avg_score])

    # Filter by author if specified
    selected_authors =
      if author_filter do
        # Find authors matching the filter (case-insensitive partial match)
        matching =
          author_stats
          |> Enum.filter(fn stat ->
            String.contains?(
              String.downcase(stat.author),
              String.downcase(author_filter)
            )
          end)

        if Enum.empty?(matching) do
          IO.puts("❌ No author found matching: #{author_filter}")
          IO.puts("\nAvailable authors:")
          author_stats |> Enum.each(fn stat -> IO.puts("  - #{stat.author}") end)
          System.halt(1)
        end

        matching
      else
        # Pick random 3 authors (or all if less than 3)
        author_stats
        |> Enum.take_random(min(3, length(author_stats)))
      end

    # Generate the blame report
    generate_blame_report(selected_authors, author_filter != nil)
  end

  defp generate_blame_report(author_stats, single_author?) do
    if single_author? do
      # Detailed report for single author
      author = List.first(author_stats)
      IO.puts("👤 Analyzing: #{author.author}")
      IO.puts("📊 Average Score: #{author.avg_score}/100")
      IO.puts("📁 Files Analyzed: #{author.file_count}\n")
    else
      IO.puts("🎲 Randomly selected #{length(author_stats)} contributor(s) for analysis:\n")
    end

    # Build prompt for AI to generate playful blame report
    prompt = build_blame_prompt(author_stats, single_author?)

    IO.puts("🤖 Generating blame report...")
    IO.puts("(This may take a moment...)\n")

    case AI.chat(prompt, json_mode: false, stream: false) do
      {:ok, response} ->
        IO.puts(response)
        IO.puts("\n")
        :ok

      {:error, error} ->
        IO.puts("\n❌ Error generating blame report: #{error}")
        System.halt(1)
    end
  end

  defp build_blame_prompt(author_stats, single_author?) do
    authors_data =
      author_stats
      |> Enum.map(fn stat ->
        worst = stat.worst_file

        # Fetch the actual file content from git
        file_preview = get_file_preview(worst["commit_hash"], worst["path"])

        """
        Author: #{stat.author}
        Average Score: #{stat.avg_score}/100
        Files Contributed: #{stat.file_count}

        Worst Contribution:
        - File: #{worst["path"]}
        - Score: #{worst["score"]}/100
        - Beauty: #{worst["beauty"]}/10
        - Elegance: #{worst["elegance"]}/10
        - Simplicity: #{worst["simplicity"]}/10
        - Readability: #{worst["readability"]}/10
        - Personality: #{worst["personality"]}/10
        - Assessment: "#{worst["assessment"]}"
        - Commit: #{worst["commit_message"]}

        Code Preview (first 20 lines):
        ```
        #{file_preview}
        ```
        """
      end)
      |> Enum.join("\n---\n")

    focus_context =
      if single_author?,
        do: "FOCUS: Single author detailed analysis",
        else: "FOCUS: Comparing #{length(author_stats)} random contributors"

    structure =
      if single_author? do
        """
        ## 😬 The Verdict for [Author]

        One playful sentence about their coding style.

        ## 🎯 The Culprit
        **File:** [path]
        **Score:** X/100
        **The Issue:** One sentence about what makes it ugly
        **Worst Quality:** [beauty/elegance/etc] (X/10)

        ## 📝 The Evidence
        Show a snippet of the actual code (5-10 most relevant lines from the preview).
        Quote specific lines that demonstrate the issue.
        Use code formatting: ```language

        ## 💡 How to Redeem Yourself
        2-3 specific, actionable suggestions to improve

        ## 🎉 Not All Bad
        Find ONE positive thing about their contributions (avg score, file count, etc.)
        """
      else
        """
        ## 🏆 The Code Ugliness Olympics

        For each author:
        ### [Place] 🥇/🥈/🥉 [Author Name]
        - **Crime:** [Worst file path] (X/100)
        - **What Went Wrong:** One sentence
        - **The Evidence:** Show 3-5 most interesting/problematic lines from the code preview
        - **Sentence:** One playful punishment/suggestion

        ## 📊 Rankings
        Show authors ranked by average score (worst to best)
        """
      end

    Prompts.blame(authors_data, focus_context, structure)
  end

  defp get_file_preview(commit_hash, file_path) do
    case System.cmd("git", ["show", "#{commit_hash}:#{file_path}"]) do
      {content, 0} ->
        # Take first 20 lines and truncate long lines
        content
        |> String.split("\n")
        |> Enum.take(20)
        |> Enum.map(fn line ->
          if String.length(line) > 80 do
            String.slice(line, 0..79) <> "..."
          else
            line
          end
        end)
        |> Enum.join("\n")

      _ ->
        "[Could not read file content]"
    end
  end
end

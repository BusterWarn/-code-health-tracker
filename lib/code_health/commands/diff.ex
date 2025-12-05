defmodule CodeHealth.Commands.Diff do
  @moduledoc """
  Compare health between two points in time.
  """

  alias CodeHealth.{AI, Prompts}

  @report_file ".code-health-report.json"

  def run_last(n) when n >= 2 do
    unless File.exists?(@report_file) do
      IO.puts("❌ No health report found. Run 'code-health init' first.")
      System.halt(1)
    end

    # Load report
    report = File.read!(@report_file) |> Jason.decode!()
    commits = report["commits"]

    if length(commits) < n do
      IO.puts("❌ Not enough commits in report. Found #{length(commits)}, need #{n}.")
      IO.puts("Run 'code-health init --commits #{n}' to analyze more commits.")
      System.halt(1)
    end

    # Get the last N commits (they're already in reverse chronological order)
    commits_to_compare = Enum.take(commits, n)

    # Compare oldest to newest (last to first in the list)
    oldest = List.last(commits_to_compare)
    newest = List.first(commits_to_compare)

    IO.puts("📊 Comparing last #{n} commits:")
    IO.puts("  From: #{String.slice(oldest["hash"], 0..6)} (#{oldest["message"]})")
    IO.puts("  To:   #{String.slice(newest["hash"], 0..6)} (#{newest["message"]})")
    IO.puts("")

    run(oldest["hash"], newest["hash"])
  end

  def run_last(_) do
    IO.puts("❌ --last requires a number >= 2")
    System.halt(1)
  end

  def run(commit1, commit2) do
    unless File.exists?(@report_file) do
      IO.puts("❌ No health report found. Run 'code-health init' first.")
      System.halt(1)
    end

    IO.puts("📊 Comparing #{commit1} → #{commit2}...\n")

    # Load report
    report = File.read!(@report_file) |> Jason.decode!()

    # Find commits in report
    commits = report["commits"]
    commit1_data = find_commit(commits, commit1)
    commit2_data = find_commit(commits, commit2)

    unless commit1_data && commit2_data do
      IO.puts("❌ One or both commits not found in report.")
      IO.puts("Available commits:")
      Enum.each(commits, fn c -> IO.puts("  - #{c["hash"]} (#{c["message"]})") end)
      System.halt(1)
    end

    # Build comparison data
    comparison_report = build_comparison(report, commit1_data, commit2_data)
    json_content = Jason.encode!(comparison_report, pretty: true)

    # Build prompt
    prompt =
      Prompts.diff(
        commit1_data["hash"],
        commit1_data["date"],
        commit2_data["hash"],
        commit2_data["date"],
        json_content
      )

    # Call OpenAI
    IO.puts("(This may take a moment...)\n")

    case AI.chat(prompt, json_mode: false, stream: false) do
      {:ok, response} ->
        IO.puts(response)
        IO.puts("")
        :ok

      {:error, error} ->
        IO.puts("\n❌ Error generating diff: #{error}")
        System.halt(1)
    end
  end

  defp find_commit(commits, identifier) do
    Enum.find(commits, fn c ->
      String.starts_with?(c["hash"], identifier) || identifier == "HEAD"
    end)
  end

  defp build_comparison(report, commit1, commit2) do
    %{
      "repository" => report["repository"],
      "commit1" => commit1,
      "commit2" => commit2,
      "score_change" => commit2["score"] - commit1["score"]
    }
  end
end

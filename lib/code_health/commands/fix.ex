defmodule CodeHealth.Commands.Fix do
  @moduledoc """
  Get improvement suggestions for a specific file.
  """

  alias CodeHealth.{Git, AI, Prompts}

  @report_file ".code-health-report.json"

  def run(file_path) do
    unless File.exists?(@report_file) do
      IO.puts("❌ No health report found. Run 'code-health init' first.")
      System.halt(1)
    end

    unless File.exists?(file_path) do
      IO.puts("❌ File not found: #{file_path}")
      System.halt(1)
    end

    IO.puts("💡 Analyzing #{file_path}...\n")

    # Load report and find file scores
    report = File.read!(@report_file) |> Jason.decode!()

    file_scores = find_file_scores(report, file_path)

    file_scores =
      if file_scores do
        file_scores
      else
        IO.puts("⚠️  File not found in report. Analyzing with default scores...")

        %{
          "score" => 50,
          "beauty" => 5,
          "elegance" => 5,
          "simplicity" => 5,
          "readability" => 5,
          "personality" => 5,
          "assessment" => "No previous assessment available."
        }
      end

    # Read current file content
    {:ok, file_content} = Git.get_current_file(file_path)

    # Build prompt
    prompt =
      Prompts.fix(
        file_path,
        file_scores["score"],
        file_scores["beauty"],
        file_scores["elegance"],
        file_scores["simplicity"],
        file_scores["readability"],
        file_scores["personality"],
        file_scores["assessment"],
        file_content
      )

    # Call OpenAI
    IO.puts("💡 Generating suggestions for #{file_path} (Score: #{file_scores["score"]}/100)")
    IO.puts("(This may take a moment...)\n")

    case AI.chat(prompt, json_mode: false, stream: false) do
      {:ok, response} ->
        IO.puts(response)
        IO.puts("")
        :ok

      {:error, error} ->
        IO.puts("\n❌ Error getting suggestions: #{error}")
        System.halt(1)
    end
  end

  defp find_file_scores(report, file_path) do
    report["commits"]
    |> Enum.flat_map(& &1["files"])
    |> Enum.find(&(&1["path"] == file_path))
  end
end

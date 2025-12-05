defmodule CodeHealth.Commands.Top do
  @moduledoc """
  Show best or worst files from the health report.
  """

  alias CodeHealth.{AI, Prompts}

  @report_file ".code-health-report.json"

  def run(%{mode: mode, count: count}) do
    unless File.exists?(@report_file) do
      IO.puts("❌ No health report found. Run 'code-health init' first.")
      System.halt(1)
    end

    mode_str = if mode == :best, do: "best", else: "worst"
    IO.puts("📊 Finding #{mode_str} files...\n")

    # Load report
    report = File.read!(@report_file) |> Jason.decode!()

    # Extract all files with scores
    all_files =
      report["commits"]
      |> Enum.flat_map(& &1["files"])
      |> Enum.uniq_by(& &1["path"])

    # Sort by score
    sorted_files =
      case mode do
        :best -> Enum.sort_by(all_files, & &1["score"], :desc)
        :worst -> Enum.sort_by(all_files, & &1["score"], :asc)
      end

    # Take top N
    top_files = Enum.take(sorted_files, count)

    # Build filtered report with the top files
    filtered_report = Map.put(report, "files", top_files)
    json_content = Jason.encode!(filtered_report, pretty: true)

    # Build prompt
    prompt = Prompts.topfiles(count, mode_str, json_content)

    # Call OpenAI
    IO.puts("(This may take a moment...)\n")

    case AI.chat(prompt, json_mode: false, stream: false) do
      {:ok, response} ->
        IO.puts(response)
        IO.puts("")
        :ok

      {:error, error} ->
        IO.puts("\n❌ Error generating top files: #{error}")
        System.halt(1)
    end
  end
end

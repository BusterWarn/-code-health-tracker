defmodule CodeHealth.Commands.Report do
  @moduledoc """
  Generate a beautiful narrative report from the health data.
  """

  alias CodeHealth.{AI, Prompts}

  @report_file ".code-health-report.json"

  def run(%{mood: mood}) do
    unless File.exists?(@report_file) do
      IO.puts("❌ No health report found. Run 'code-health init' first.")
      System.halt(1)
    end

    IO.puts("📊 Generating report in #{mood} mood...")
    IO.puts("(This may take a moment...)\n")

    # Load report
    json_content = File.read!(@report_file)

    # Build prompt
    prompt = Prompts.report(mood, json_content)

    # Call OpenAI without streaming for now (to avoid timeout issues)
    case AI.chat(prompt, json_mode: false, stream: false) do
      {:ok, response} ->
        IO.puts(response)
        IO.puts("")
        :ok

      {:error, error} ->
        IO.puts("\n❌ Error generating report: #{error}")
        System.halt(1)
    end
  end
end

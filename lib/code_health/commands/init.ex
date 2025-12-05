defmodule CodeHealth.Commands.Init do
  @moduledoc """
  Initialize code health analysis by analyzing git history.
  """

  alias CodeHealth.{Git, AI, Prompts}

  @report_file ".code-health-report.json"

  def run(%{commits: num_commits}) do
    IO.puts("🔍 Analyzing #{num_commits} commits...")

    # Gather git data
    repo_name = Git.repo_name()
    branch = Git.current_branch()
    commits = Git.get_commits(num_commits)

    if Enum.empty?(commits) do
      IO.puts("❌ No commits found. Make sure you're in a git repository.")
      System.halt(1)
    end

    # Build git log data
    git_log_data = format_git_log(commits)

    # Gather file contents for all commits
    IO.puts("📁 Reading file contents...")
    file_contents = gather_file_contents(commits)

    # Build prompt
    prompt = Prompts.init(repo_name, branch, num_commits, git_log_data, file_contents)

    # Call OpenAI (non-streaming for JSON response)
    IO.puts("🤖 Asking AI to analyze code beauty...")
    IO.puts("(This may take a moment...)")

    case AI.chat(prompt, json_mode: true, stream: false) do
      {:ok, response} ->
        case AI.parse_json_response(response) do
          {:ok, report_data} ->
            # Save report
            save_report(report_data)

            # Display summary
            display_summary(report_data)

          {:error, error} ->
            IO.puts("❌ Error parsing AI response: #{error}")
            IO.puts("\nRaw response:")
            IO.puts(response)
            System.halt(1)
        end

      {:error, error} ->
        IO.puts("❌ Error calling OpenAI: #{error}")
        System.halt(1)
    end
  end

  defp format_git_log(commits) do
    commits
    |> Enum.map(fn commit ->
      """
      Commit: #{commit.hash}
      Author: #{commit.author}
      Date: #{commit.date}
      Message: #{commit.message}
      """
    end)
    |> Enum.join("\n---\n")
  end

  defp gather_file_contents(commits) do
    commits
    |> Enum.take(20) # Limit to first 20 commits to avoid token limits
    |> Enum.flat_map(fn commit ->
      files = Git.get_commit_files(commit.hash)

      files
      |> Enum.take(5) # Limit files per commit
      |> Enum.filter(&is_text_file?/1) # Skip binary files
      |> Enum.filter(&is_code_file?/1) # Skip config files
      |> Enum.map(fn file_path ->
        case Git.get_file_at_commit(commit.hash, file_path) do
          {:ok, content} ->
            # Check if content looks like binary data
            if String.valid?(content) && String.printable?(content) do
              """
              === File: #{file_path} (Commit: #{commit.hash}) ===
              #{String.slice(content, 0..2000)}
              #{if String.length(content) > 2000, do: "\n... (truncated)", else: ""}
              """
            else
              "=== File: #{file_path} (Commit: #{commit.hash}) === [Binary file skipped]"
            end

          {:error, _} ->
            nil # Skip files that can't be read
        end
      end)
      |> Enum.reject(&is_nil/1) # Remove nil entries
    end)
    |> Enum.join("\n\n")
  end

  defp is_text_file?(path) do
    # Skip common binary file extensions
    binary_extensions = [
      ".png", ".jpg", ".jpeg", ".gif", ".bmp", ".ico", ".svg",
      ".pdf", ".zip", ".tar", ".gz", ".bz2", ".xz",
      ".exe", ".dll", ".so", ".dylib",
      ".mp3", ".mp4", ".avi", ".mov",
      ".ttf", ".otf", ".woff", ".woff2"
    ]

    ext = Path.extname(path) |> String.downcase()
    not Enum.member?(binary_extensions, ext)
  end

  defp is_code_file?(path) do
    ext = Path.extname(path) |> String.downcase()
    filename = Path.basename(path)

    ignored_extensions = [
      ".yaml", ".yml", ".json", ".toml", ".ini", ".conf",
      ".xml", ".md", ".txt", ".rst",
      ".csv", ".tsv", ".env", ".lock", ".log",
      "mix.exs", "config.exs"
    ]

    # ignore dotfiles or mix.exs specifically
    is_dotfile = String.starts_with?(filename, ".")
    is_mix_exs = filename == "mix.exs"

    not (Enum.member?(ignored_extensions, ext) or is_dotfile or is_mix_exs); # semicolon flex ;)
  end

  defp save_report(report_data) do
    json = Jason.encode!(report_data, pretty: true)
    File.write!(@report_file, json)
  end

  defp display_summary(report_data) do
    overall_score = report_data["overall_score"]

    IO.puts("\n✨ Done! Overall health: #{overall_score}/100")
    IO.puts("📄 Created: #{@report_file}")

    if summary = report_data["summary"] do
      IO.puts("\n🌟 Most beautiful: #{summary["most_beautiful"]}")
      IO.puts("😓 Needs love: #{summary["needs_most_love"]}")
    end
  end
end

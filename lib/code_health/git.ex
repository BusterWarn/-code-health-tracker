defmodule CodeHealth.Git do
  @moduledoc """
  Git operations for extracting commit history and file contents.
  """

  @doc """
  Get the repository name from git config.
  """
  def repo_name do
    case System.cmd("git", ["config", "--get", "remote.origin.url"]) do
      {url, 0} ->
        url
        |> String.trim()
        |> String.split("/")
        |> List.last()
        |> String.replace(".git", "")

      _ ->
        "unknown-repo"
    end
  end

  @doc """
  Get current branch name.
  """
  def current_branch do
    case System.cmd("git", ["rev-parse", "--abbrev-ref", "HEAD"]) do
      {branch, 0} -> String.trim(branch)
      _ -> "main"
    end
  end

  @doc """
  Get commit history with details.
  Returns a list of maps with commit information.
  """
  def get_commits(count) do
    format = "%H|%an|%ae|%aI|%s"

    case System.cmd("git", ["log", "-#{count}", "--pretty=format:#{format}"]) do
      {output, 0} ->
        output
        |> String.split("\n")
        |> Enum.filter(&(&1 != ""))
        |> Enum.map(&parse_commit_line/1)

      {error, _} ->
        IO.puts("Error getting git log: #{error}")
        []
    end
  end

  defp parse_commit_line(line) do
    [hash, author_name, author_email, date, message] = String.split(line, "|", parts: 5)

    %{
      hash: hash,
      author: author_email,
      author_name: author_name,
      date: date,
      message: message
    }
  end

  @doc """
  Get files changed in a specific commit.
  """
  def get_commit_files(commit_hash) do
    case System.cmd("git", ["diff-tree", "--no-commit-id", "--name-only", "-r", commit_hash]) do
      {output, 0} ->
        output
        |> String.split("\n")
        |> Enum.filter(&(&1 != ""))

      _ ->
        []
    end
  end

  @doc """
  Get file content at a specific commit.
  """
  def get_file_at_commit(commit_hash, file_path) do
    case System.cmd("git", ["show", "#{commit_hash}:#{file_path}"]) do
      {content, 0} -> {:ok, content}
      _ -> {:error, "Could not read file"}
    end
  end

  @doc """
  Get current file content from working directory.
  """
  def get_current_file(file_path) do
    case File.read(file_path) do
      {:ok, content} -> {:ok, content}
      error -> error
    end
  end

  @doc """
  Count lines in content.
  """
  def count_lines(content) do
    content
    |> String.split("\n")
    |> length()
  end

  @doc """
  Estimate function count (simple heuristic based on common patterns).
  """
  def count_functions(content) do
    # Simple pattern matching for common function definitions
    patterns = [
      ~r/\bfn\s+\w+/,           # Rust/Elixir
      ~r/\bdef\s+\w+/,          # Python/Ruby/Elixir
      ~r/\bfunction\s+\w+/,     # JavaScript
      ~r/\bfunc\s+\w+/,         # Go
      ~r/\b\w+\s*\([^)]*\)\s*{/ # C-style
    ]

    patterns
    |> Enum.map(fn pattern ->
      Regex.scan(pattern, content) |> length()
    end)
    |> Enum.max()
  end
end

defmodule CodeHealth.Prompts do
  @moduledoc """
  Loads and processes prompt templates for OpenAI interactions.
  """

  @prompts_dir Path.join([__DIR__, "../../prompts"])

  @doc """
  Load and interpolate the init prompt.
  Note: The actual init prompt is in report.txt (naming inconsistency in source files).
  """
  def init(repo_name, branch, num_commits, git_log_data, file_contents) do
    @prompts_dir
    |> Path.join("report.txt")
    |> File.read!()
    |> String.replace("{repo_name}", repo_name)
    |> String.replace("{branch}", branch)
    |> String.replace("{num_commits}", to_string(num_commits))
    |> String.replace("{git_log_data}", git_log_data)
    |> String.replace("{file_contents}", file_contents)
  end

  @doc """
  Load and interpolate the report prompt.
  Note: This loads from a separate report prompt file for narrative generation.
  """
  def report(mood, json_content) do
    # Check if there's a narrative report prompt, otherwise construct one
    report_path = Path.join(@prompts_dir, "narrative_report.txt")

    prompt_content =
      if File.exists?(report_path) do
        File.read!(report_path)
      else
        # Use a constructed prompt based on the spec
        """
        You are a code quality reporter. Be concise but include the ASCII timeline.

        MOOD: #{mood} (professional=clear, cheerful=upbeat, sarcastic=witty, poet=metaphorical)
        DATA: #{json_content}

        TASK: Create a focused report (max 300 words).

        STRUCTURE:

        ## Overview
        Overall score: X/100
        One-sentence verdict about the codebase

        ## Timeline
        **CRITICAL:** Create a DETAILED ASCII graph showing score trends across commits.

        Requirements:
        - Use box-drawing characters: ─ │ ╭ ╮ ╰ ╯ ┤ ├ ┬ ┴ ┼
        - Height: 15-20 lines (cover full range from lowest to highest score + padding)
        - Width: 70-80 characters wide
        - Y-axis: Show score values every 5-10 points (e.g., 100, 90, 80, 70...)
        - X-axis: Add date labels or commit markers below (e.g., commit numbers, short dates)
        - Show EVERY data point - connect all commits with smooth curves
        - Mark peaks with ╭─╮ and valleys with ╰─╯
        - Add trend indicators: ↗ for improving, ↘ for declining
        - Label the highest and lowest points with their actual scores

        Example of the detail level expected:
        ```
        100 ┤
         95 ┤                    ╭──╮
         90 ┤                ╭───╯  ╰─╮
         85 ┤            ╭───╯        ╰──╮
         80 ┤        ╭───╯               ╰─╮
         75 ┤    ╭───╯                     ╰──╮
         70 ┤╭───╯                            ╰─╮
         65 ┤╯                                  ╰──
         60 ┤
            └──────────────────────────────────────→
             #1   #2   #3   #4   #5   #6   #7   #8
             Nov15 Nov18 Nov22 Nov25 Nov29 Dec1  Dec3
        ```

        Make it information-rich and easy to read!

        ## 🌟 Top 2 Best Files
        1. **file.path** (score) - why it's good
        2. **file.path** (score) - why it's good

        ## 😓 Top 2 Needing Work
        1. **file.path** (score) - what to fix
        2. **file.path** (score) - what to fix

        ## Next Action
        One specific, actionable recommendation

        STYLE:
        - The ASCII timeline is MANDATORY - don't skip it
        - Keep text sections brief
        - Match the mood
        - Use emojis sparingly

        Output as markdown.
        """
      end

    prompt_content
    |> String.replace("{mood}", mood)
    |> String.replace("{json_content}", json_content)
  end

  @doc """
  Load and interpolate the fix prompt.
  Note: The actual fix prompt is in init.txt (naming inconsistency in source files).
  """
  def fix(file_path, overall_score, beauty, elegance, simplicity, readability, personality, assessment, file_content) do
    @prompts_dir
    |> Path.join("init.txt")
    |> File.read!()
    |> String.replace("{file_path}", file_path)
    |> String.replace("{overall_score}", to_string(overall_score))
    |> String.replace("{beauty}", to_string(beauty))
    |> String.replace("{elegance}", to_string(elegance))
    |> String.replace("{simplicity}", to_string(simplicity))
    |> String.replace("{readability}", to_string(readability))
    |> String.replace("{personality}", to_string(personality))
    |> String.replace("{assessment}", assessment)
    |> String.replace("{file_content}", file_content)
  end

  @doc """
  Load and interpolate the diff prompt.
  """
  def diff(commit1_hash, commit1_date, commit2_hash, commit2_date, json_content) do
    @prompts_dir
    |> Path.join("diff.txt")
    |> File.read!()
    |> String.replace("{commit1_hash}", commit1_hash)
    |> String.replace("{commit1_date}", commit1_date)
    |> String.replace("{commit2_hash}", commit2_hash)
    |> String.replace("{commit2_date}", commit2_date)
    |> String.replace("{json_content}", json_content)
  end

  @doc """
  Load and interpolate the topfiles prompt.
  """
  def topfiles(n, best_or_worst, json_content) do
    @prompts_dir
    |> Path.join("topfiles.txt")
    |> File.read!()
    |> String.replace("{n}", to_string(n))
    |> String.replace("{best_or_worst}", best_or_worst)
    |> String.replace("{json_content}", json_content)
  end

  @doc """
  Load and interpolate the blame prompt.
  """
  def blame(authors_data, focus_context, structure) do
    @prompts_dir
    |> Path.join("blame.txt")
    |> File.read!()
    |> String.replace("{authors_data}", authors_data)
    |> String.replace("{focus_context}", focus_context)
    |> String.replace("{structure}", structure)
  end
end

defmodule CodeHealth do
  @moduledoc """
  Code Health Tracker - Give your codebase a beauty score.

  This tool uses AI to judge code like an art critic - focusing on
  elegance, readability, and the joy of reading it.
  """

  @doc """
  Main entry point for the application.
  """
  def main(args) do
    CodeHealth.CLI.main(args)
  end
end

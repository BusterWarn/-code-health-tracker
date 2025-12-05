defmodule CodeHealthTest do
  use ExUnit.Case
  doctest CodeHealth

  test "git module can get repo info" do
    # Basic smoke test
    repo_name = CodeHealth.Git.repo_name()
    assert is_binary(repo_name)
  end
end

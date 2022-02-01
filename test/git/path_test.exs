defmodule GitHooks.Git.PathTest do
  use ExUnit.Case

  alias GitHooks.Git.Path

  describe "git_hooks_path_for/1" do
    test "appends the path to the hooks folder" do
      assert Path.git_hooks_path_for("/testing") == ".git/hooks/testing"
    end
  end
end

defmodule GitHooks.Git.PathTest do
  use ExUnit.Case

  alias GitHooks.Git.Path

  describe "git_hooks_path_for/1" do
    test "appends the path to the hooks folder" do
      assert Path.git_hooks_path_for("/testing") == ".git/hooks/testing"
    end
  end

  describe "resolve_git_hooks_path/0" do
    test "returns the git path of the project" do
      assert Path.resolve_git_hooks_path() == ".git/hooks"
    end
  end
end

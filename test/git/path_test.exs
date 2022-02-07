defmodule GitHooks.Git.PathTest do
  use ExUnit.Case

  alias GitHooks.Git.Path

  describe "git_hooks_path_for/1" do
    test "appends the path to the hooks folder" do
      assert Path.git_hooks_path_for("/testing") == ".git/hooks/testing"
    end
  end

  describe "resolve_git_hooks_path/0" do
    test "returns the configuration for git_hooks_path" do
      Application.put_env(:git_hooks, :git_hooks_path, "./custom-hooks-path")

      assert Path.resolve_git_hooks_path() == "./custom-hooks-path"

      Application.delete_env(:git_hooks, :git_hooks_path)
    end

    test "returns the hooks path based on the git_path configuration" do
      Application.put_env(:git_hooks, :git_path, "./custom-git-path")

      assert Path.resolve_git_hooks_path() == "./custom-git-path/hooks"

      Application.delete_env(:git_hooks, :git_path)
    end

    test "prioritizes the git_hooks_path config over the git_path" do
      Application.put_env(:git_hooks, :git_hooks_path, "./prioritized-custom-hooks-path")
      Application.put_env(:git_hooks, :git_path, "./custom-git-path")

      assert Path.resolve_git_hooks_path() == "./prioritized-custom-hooks-path"

      Application.delete_env(:git_hooks, :git_hooks_path)
      Application.delete_env(:git_hooks, :git_path)
    end

    test "returns the git path when there is no other configuration" do
      assert Path.resolve_git_hooks_path() == ".git/hooks"
    end
  end
end

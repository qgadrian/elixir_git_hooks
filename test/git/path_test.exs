defmodule GitHooks.Git.PathTest do
  use ExUnit.Case
  use GitHooks.TestSupport.GitProjectCase

  alias GitHooks.Git.GitPath

  describe "git_hooks_path_for/1" do
    test "appends the path to the `.git/hooks` folder", %{tmp_dir: project_path} do
      assert GitPath.git_hooks_path_for("/testing") == "#{project_path}/.git/hooks/testing"
    end
  end

  describe "resolve_git_hooks_path/0" do
    test "returns the git path of the project", %{tmp_dir: project_path} do
      assert GitPath.resolve_git_hooks_path() == "#{project_path}/.git/hooks"
    end
  end
end

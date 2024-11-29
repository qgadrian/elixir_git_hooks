defmodule GitHooks.Git.PathTest do
  use ExUnit.Case
  use GitHooks.TestSupport.GitProjectCase

  alias GitHooks.Git.GitPath

  @tag capture_log: true

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

  describe "resolve_app_path/0" do
    test "returns the project root when called from the project directory", %{
      tmp_dir: project_path
    } do
      assert GitPath.resolve_app_path() == project_path
    end

    test "returns the project root when called from the dependency directory", %{
      tmp_dir: project_path
    } do
      # Simulates being in the dependency directory
      deps_git_hooks_dir = Path.join([project_path, "deps", "git_hooks"])
      File.mkdir_p!(deps_git_hooks_dir)

      File.cd!(deps_git_hooks_dir, fn ->
        assert GitPath.resolve_app_path() == project_path
      end)
    end
  end
end

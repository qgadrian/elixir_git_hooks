defmodule GitHooks.Git.PathTest do
  use ExUnit.Case

  alias GitHooks.Git.Path

  describe "git_hooks_path_for/1" do
    setup [:project_path]

    test "appends the path to the `.git/hooks` folder", %{project_path: project_path} do
      assert Path.git_hooks_path_for("/testing") == "#{project_path}/.git/hooks/testing"
    end
  end

  describe "resolve_git_hooks_path/0" do
    setup [:project_path]

    test "returns the git path of the project", %{project_path: project_path} do
      assert Path.resolve_git_hooks_path() == "#{project_path}/.git/hooks"
    end
  end

  #
  # Private functions
  #

  defp project_path(_) do
    {project_path, 0} = System.cmd("pwd", [])
    project_path = String.replace(project_path, ~r/\n/, "")

    {:ok, %{project_path: project_path}}
  end
end

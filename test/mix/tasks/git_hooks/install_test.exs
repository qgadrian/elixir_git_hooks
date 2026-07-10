defmodule Mix.Tasks.InstallTest do
  @moduledoc false

  use ExUnit.Case, async: false
  use GitHooks.TestSupport.ConfigCase
  use GitHooks.TestSupport.GitProjectCase

  alias Mix.Tasks.GitHooks.Install

  @moduletag capture_log: true

  describe "run/1" do
    test "replaces the hook template with config values", %{tmp_dir: project_path} do
      put_git_hook_config(
        [:pre_commit, :pre_push],
        tasks: {:cmd, "check"}
      )

      hooks_file = Install.run(["--dry-run", "--quiet"])

      assert hooks_file == [
               pre_commit: expect_hook_template("pre_commit", project_path),
               pre_push: expect_hook_template("pre_push", project_path)
             ]
    end

    test "allows setting a custom path to execute the hook", %{tmp_dir: project_path} do
      put_git_hook_config(
        [:pre_commit, :pre_push],
        tasks: {:cmd, "check"}
      )

      custom_path = Path.join(project_path, "a_custom_path")
      File.mkdir_p!(custom_path)
      System.cmd("git", ["init"], cd: custom_path)
      Application.put_env(:git_hooks, :project_path, custom_path)

      hooks_file = Install.run(["--dry-run", "--quiet"])

      assert hooks_file == [
               pre_commit: expect_hook_template("pre_commit", custom_path),
               pre_push: expect_hook_template("pre_push", custom_path)
             ]

      Application.delete_env(:git_hooks, :project_path)
    end

    test "installs git hooks when run from the project root", %{tmp_dir: project_path} do
      put_git_hook_config(
        [:pre_commit, :pre_push],
        tasks: {:cmd, "check"}
      )

      hooks_file = Install.run(["--dry-run", "--quiet"])

      assert hooks_file == [
               pre_commit: expect_hook_template("pre_commit", project_path),
               pre_push: expect_hook_template("pre_push", project_path)
             ]
    end

    test "uses the current worktree when no project path is set", %{tmp_dir: project_path} do
      # Simulate being in the dependency directory
      deps_git_hooks_dir = Path.join([project_path, "deps", "git_hooks"])
      File.mkdir_p!(deps_git_hooks_dir)

      File.cd!(deps_git_hooks_dir, fn ->
        # GitProjectCase sets :project_path; remove it to test the default.
        Application.delete_env(:git_hooks, :project_path)

        put_git_hook_config(
          [:pre_commit, :pre_push],
          tasks: {:cmd, "check"}
        )

        hooks_file = Install.run(["--dry-run", "--quiet"])

        # No project path: the hook finds the working tree when it runs, so one
        # shared script works from any worktree.
        worktree_lookup = "$(git rev-parse --show-toplevel)"

        assert hooks_file == [
                 pre_commit: expect_hook_template("pre_commit", worktree_lookup),
                 pre_push: expect_hook_template("pre_push", worktree_lookup)
               ]
      end)
    end
  end

  #
  # Private functions
  #

  defp expect_hook_template(git_hook, project_path) do
    ~s(#!/bin/sh

cd_path="#{project_path}"
[ -n "$cd_path" ] && cd "$cd_path"

mix git_hooks.run #{git_hook} "$@"
[ $? -ne 0 ] && exit 1
exit 0
)
  end
end

defmodule Mix.Tasks.InstallTest do
  @moduledoc false

  use ExUnit.Case, async: false
  use GitHooks.TestSupport.ConfigCase
  use GitHooks.TestSupport.GitProjectCase

  alias Mix.Tasks.GitHooks.Install

  @tag capture_log: true

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

    test "installs git hooks when run from the dependency directory", %{tmp_dir: project_path} do
      # Simulate being in the dependency directory
      deps_git_hooks_dir = Path.join([project_path, "deps", "git_hooks"])
      File.mkdir_p!(deps_git_hooks_dir)

      File.cd!(deps_git_hooks_dir, fn ->
        # Need to reset the config cache because Application env might be cached
        Application.delete_env(:git_hooks, :project_path)

        put_git_hook_config(
          [:pre_commit, :pre_push],
          tasks: {:cmd, "check"}
        )

        hooks_file = Install.run(["--dry-run", "--quiet"])

        # Use the resolved git path to fix symlinks on SO (such as macOS)
        # This is not ideal, but using `Path.expand(project_path)` instead
        # is not working because in macOS /var is a symlink to /private/var
        resolved_project_path = GitHooks.Git.GitPath.resolve_app_path()

        assert hooks_file == [
                 pre_commit: expect_hook_template("pre_commit", resolved_project_path),
                 pre_push: expect_hook_template("pre_push", resolved_project_path)
               ]
      end)
    end
  end

  #
  # Private functions
  #

  defp expect_hook_template(git_hook, project_path) do
    ~s(#!/bin/sh

[ "#{project_path}" != "" ] && cd "#{project_path}"

mix git_hooks.run #{git_hook} "$@"
[ $? -ne 0 ] && exit 1
exit 0
)
  end
end

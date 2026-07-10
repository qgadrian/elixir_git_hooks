defmodule Mix.Tasks.InstallTest do
  @moduledoc false

  use ExUnit.Case, async: false
  use GitHooks.TestSupport.ConfigCase
  use GitHooks.TestSupport.GitProjectCase

  import ExUnit.CaptureIO

  alias Mix.Tasks.GitHooks.Install

  @moduletag capture_log: true

  setup do
    external_override = System.get_env("GIT_HOOKS_ALLOW_EXTERNAL")
    System.delete_env("GIT_HOOKS_ALLOW_EXTERNAL")

    on_exit(fn ->
      if external_override do
        System.put_env("GIT_HOOKS_ALLOW_EXTERNAL", external_override)
      else
        System.delete_env("GIT_HOOKS_ALLOW_EXTERNAL")
      end
    end)

    :ok
  end

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
      System.cmd("git", ["-c", "init.defaultBranch=master", "init", "--quiet"], cd: custom_path)
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

    test "refuses to install when hooks path is outside the repo", %{tmp_dir: project_path} do
      put_git_hook_config(
        [:pre_commit, :pre_push],
        tasks: {:cmd, "check"}
      )

      external_hooks_dir = configure_external_hooks_path(project_path)
      existing_hook = Path.join(external_hooks_dir, "pre-commit")
      File.write!(existing_hook, "existing shared hook")

      output =
        capture_io(fn ->
          assert Install.run(["--quiet"]) == :ok
        end)

      assert output =~ "Refusing to install git hooks outside the repository."
      assert File.read!(existing_hook) == "existing shared hook"
      refute File.exists?(Path.join(external_hooks_dir, "pre-push"))
      refute File.exists?(Path.join(external_hooks_dir, "git_hooks.db"))
    end

    test "allows install when hooks path is outside the repo with explicit opt-in", %{
      tmp_dir: project_path
    } do
      put_git_hook_config(
        [:pre_commit, :pre_push],
        tasks: {:cmd, "check"}
      )

      external_hooks_dir = configure_external_hooks_path(project_path)
      Application.put_env(:git_hooks, :allow_external_hooks_path, true)

      assert Install.run(["--quiet"]) == :ok

      assert File.read!(Path.join(external_hooks_dir, "pre-commit")) ==
               expect_hook_template("pre_commit", project_path)

      assert File.read!(Path.join(external_hooks_dir, "pre-push")) ==
               expect_hook_template("pre_push", project_path)
    end

    test "allows install when the environment opts into an external hooks path", %{
      tmp_dir: project_path
    } do
      put_git_hook_config(
        [:pre_commit, :pre_push],
        tasks: {:cmd, "check"}
      )

      configure_external_hooks_path(project_path)
      System.put_env("GIT_HOOKS_ALLOW_EXTERNAL", "yes")

      hooks_file = Install.run(["--dry-run", "--quiet"])

      assert hooks_file == [
               pre_commit: expect_hook_template("pre_commit", project_path),
               pre_push: expect_hook_template("pre_push", project_path)
             ]
    end

    test "allows the shared hooks directory from a linked worktree", %{tmp_dir: project_path} do
      put_git_hook_config(
        [:pre_commit, :pre_push],
        tasks: {:cmd, "check"}
      )

      File.write!(Path.join(project_path, "README.md"), "test repository")
      git!(project_path, ["add", "README.md"])

      git!(project_path, [
        "-c",
        "user.name=Git Hooks Test",
        "-c",
        "user.email=git-hooks@example.com",
        "commit",
        "--quiet",
        "-m",
        "Initial commit"
      ])

      worktree_path = unique_tmp_path("git_hooks_worktree")
      on_exit(fn -> File.rm_rf(worktree_path) end)

      git!(project_path, [
        "worktree",
        "add",
        "--quiet",
        "-b",
        "linked-worktree",
        worktree_path
      ])

      Application.put_env(:git_hooks, :project_path, worktree_path)

      hooks_file = Install.run(["--dry-run", "--quiet"])

      assert hooks_file == [
               pre_commit: expect_hook_template("pre_commit", worktree_path),
               pre_push: expect_hook_template("pre_push", worktree_path)
             ]
    end

    test "allows the Git hooks directory for a submodule", %{tmp_dir: project_path} do
      put_git_hook_config(
        [:pre_commit, :pre_push],
        tasks: {:cmd, "check"}
      )

      source_path = unique_tmp_path("git_hooks_submodule_source")
      File.mkdir_p!(source_path)
      on_exit(fn -> File.rm_rf(source_path) end)

      git!(source_path, ["-c", "init.defaultBranch=master", "init", "--quiet"])
      File.write!(Path.join(source_path, "README.md"), "test submodule")
      git!(source_path, ["add", "README.md"])

      git!(source_path, [
        "-c",
        "user.name=Git Hooks Test",
        "-c",
        "user.email=git-hooks@example.com",
        "commit",
        "--quiet",
        "-m",
        "Initial commit"
      ])

      submodule_path = Path.join(project_path, "submodule")

      git!(project_path, [
        "-c",
        "protocol.file.allow=always",
        "submodule",
        "add",
        "--quiet",
        source_path,
        submodule_path
      ])

      Application.put_env(:git_hooks, :project_path, submodule_path)

      hooks_file = Install.run(["--dry-run", "--quiet"])

      assert hooks_file == [
               pre_commit: expect_hook_template("pre_commit", submodule_path),
               pre_push: expect_hook_template("pre_push", submodule_path)
             ]
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

  defp configure_external_hooks_path(project_path) do
    external_hooks_dir = unique_tmp_path("git_hooks_external")
    File.mkdir_p!(external_hooks_dir)
    on_exit(fn -> File.rm_rf(external_hooks_dir) end)

    git!(project_path, ["config", "core.hooksPath", external_hooks_dir])

    external_hooks_dir
  end

  defp git!(project_path, args) do
    {output, exit_status} =
      System.cmd("git", args, cd: project_path, stderr_to_stdout: true)

    assert exit_status == 0, output

    String.trim(output)
  end

  defp unique_tmp_path(prefix) do
    Path.join(System.tmp_dir!(), "#{prefix}_#{System.unique_integer([:positive])}")
  end
end

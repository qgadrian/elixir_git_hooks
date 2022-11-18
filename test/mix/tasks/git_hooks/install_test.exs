defmodule Mix.Tasks.InstallTest do
  @moduledoc false

  use ExUnit.Case, async: false
  use GitHooks.TestSupport.ConfigCase

  alias Mix.Tasks.GitHooks.Install

  @tag capture_log: true

  describe "run/1" do
    test "replaces the hook template with config values" do
      put_git_hook_config(
        [:pre_commit, :pre_push],
        tasks: {:cmd, "check"}
      )

      hooks_file = Install.run(["--dry-run", "--quiet"])

      assert hooks_file == [
               pre_commit: expect_hook_template("pre_commit"),
               pre_push: expect_hook_template("pre_push")
             ]
    end

    test "allows setting a custom path to execute the hook" do
      put_git_hook_config(
        [:pre_commit, :pre_push],
        tasks: {:cmd, "check"}
      )

      Application.put_env(:git_hooks, :project_path, "a_custom_path")

      hooks_file = Install.run(["--dry-run", "--quiet"])

      assert hooks_file == [
               pre_commit: expect_hook_template("pre_commit", "a_custom_path"),
               pre_push: expect_hook_template("pre_push", "a_custom_path")
             ]

      Application.delete_env(:git_hooks, :project_path)
    end
  end

  #
  # Private functions
  #

  defp expect_hook_template(git_hook, project_path \\ "") do
    ~s(#!/bin/sh

[ "#{project_path}" != "" ] && cd "#{project_path}"

mix git_hooks.run #{git_hook} "$@"
[ $? -ne 0 ] && exit 1
exit 0
)
  end
end

defmodule Mix.Tasks.InstallTest do
  @moduledoc false

  use ExUnit.Case, async: false
  use GitHooks.TestSupport.ConfigCase

  alias Mix.Tasks.GitHooks.Install
  alias GitHooks.Git.Path, as: GitPath

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
  end

  #
  # Private functions
  #

  defp expect_hook_template(git_hook) do
    app_path = GitPath.resolve_app_path()

    ~s(#!/bin/sh

[ "#{app_path}" != "" ] && cd "#{app_path}"

mix git_hooks.run #{git_hook} "$@"
[ $? -ne 0 ] && exit 1
exit 0
)
  end
end

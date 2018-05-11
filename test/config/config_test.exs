defmodule GitHooks.ConfigTest do
  @moduledoc false

  use ExUnit.Case, async: false
  use GitHooks.TestSupport.ConfigCase

  alias GitHooks.Config

  describe "Given a git hook type" do
    test "when there are not configured mix tasks then an empty list is returned" do
      put_git_hook_config(:pre_commit, mix_tasks: ["help", "help deps"])

      assert Config.mix_tasks(:unknown_hook) == {:unknown_hook, []}
    end

    test "when there are configured mix tasks then a list of the mix tasks is returned" do
      mix_tasks = ["help", "help deps"]

      put_git_hook_config(:pre_commit, mix_tasks: mix_tasks)

      assert Config.mix_tasks(:pre_commit) == {:pre_commit, mix_tasks}
    end

    test "when the verbose is enabled for the git hook then the verbose config function returns true" do
      put_git_hook_config(:pre_commit, verbose: true)

      assert Config.verbose?(:pre_commit) == true
    end

    test "when the verbose is enabled globally then the verbose config function returns true" do
      Application.put_env(:git_hooks, :verbose, true)

      assert Config.verbose?(:pre_commit) == true
    end

    test "when the verbose is true globally but false for a githook then the verbose config function returns false" do
      put_git_hook_config(:pre_commit, verbose: false)
      Application.put_env(:git_hooks, :verbose, true)

      assert Config.verbose?(:pre_commit) == false
    end

    test "when the git hook is unknown then the verbose config function returns false" do
      put_git_hook_config(:pre_commit, verbose: true)

      assert Config.verbose?(:unknown_hook) == false
    end

    test "when there are no supported git hooks configured then an empty list is returned" do
      assert Config.git_hooks() == []
    end

    test "when request the git hooks types then a list of supported git hooks types is returned" do
      put_git_hook_configs([:pre_commit, :pre_push])

      assert Config.git_hooks() == [:pre_commit, :pre_push]
    end

    test "when the verbose is enabled then a IO stream is returned" do
      put_git_hook_configs([:pre_commit], verbose: true)

      assert Config.io_stream(:pre_commit) == IO.stream(:stdio, :line)
    end

    test "when the verbose is disabled then an empty string is returned" do
      put_git_hook_configs([:pre_commit, :pre_push], verbose: false)

      assert Config.io_stream(:pre_commit) == ""
    end
  end
end

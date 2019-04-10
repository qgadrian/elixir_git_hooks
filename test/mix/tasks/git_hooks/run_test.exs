defmodule Mix.Tasks.RunTest do
  @moduledoc false

  use ExUnit.Case, async: false
  use GitHooks.TestSupport.ConfigCase

  import ExUnit.CaptureIO

  doctest Mix.Tasks.GitHooks.Run

  alias Mix.Tasks.GitHooks.Run

  describe "Given args for the mix git hook task" do
    test "when no git hook type is provided then the process exits with 1" do
      capture_io(fn ->
        assert catch_exit(Run.run([])) == 1
      end)
    end

    test "when the git hook type is not supported then the process exits with 1" do
      capture_io(fn ->
        assert catch_exit(Run.run(["invalid_hook"])) == 1
      end)
    end

    test "when the git hook it's supported then it's executed and the task returns :ok" do
      put_git_hook_config(:pre_commit, tasks: ["mix help test"], verbose: true)

      capture_io(fn ->
        assert Run.run(["pre-commit"]) == :ok
      end)
    end

    test "when a mix task of the git hook fails then it's executed and the task exits with 0" do
      put_git_hook_config(:pre_commit, tasks: ["this_task_is_going_to_fail"])

      capture_io(fn ->
        assert catch_exit(Run.run(["pre-commit"])) == 1
      end)
    end
  end
end

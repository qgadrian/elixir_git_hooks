defmodule Mix.Tasks.RunTest do
  @moduledoc false

  use ExUnit.Case, async: false
  use GitHooks.TestSupport.ConfigCase

  import ExUnit.CaptureIO

  doctest Mix.Tasks.GitHooks.Run

  alias Mix.Tasks.GitHooks.Run

  describe "Given task" do
    test "when it is a file then the file it's executed" do
      put_git_hook_config(:pre_commit, tasks: [{:file, "priv/test_script"}], verbose: true)

      assert capture_io(fn ->
               assert Run.run(["pre-commit"]) == :ok
             end) =~ "Test script"
    end

    test "when it is a command then the command it's executed" do
      put_git_hook_config(:pre_commit, tasks: [{:cmd, "echo 'test command'"}], verbose: true)

      assert capture_io(fn ->
               assert Run.run(["pre-commit"]) == :ok
             end) =~ "test command"
    end

    test "when it is a string then the command it's executed" do
      put_git_hook_config(:pre_commit, tasks: ["echo 'test string command'"], verbose: true)

      assert capture_io(fn ->
               assert Run.run(["pre-commit"]) == :ok
             end) =~ "test string command"
    end

    test "when the config is unknown then an error is raised" do
      put_git_hook_config(:pre_commit,
        tasks: [{:cmd, "echo 'test string command'", :make_it_fail}],
        verbose: true
      )

      capture_io(fn ->
        assert_raise RuntimeError, fn -> Run.run(["pre-commit"]) end
      end)
    end

    test "when verbose is enabled then the execution of a mix task prints the args" do
      put_git_hook_config(:pre_commit,
        tasks: [{:cmd, "mix help clean"}],
        verbose: true
      )

      assert capture_io(fn -> Run.run(["pre-commit"]) end) =~ "`mix help clean` was successful"
    end

    test "when verbose is enabled the command and args print in the error message" do
      put_git_hook_config(:pre_commit,
        tasks: [{:cmd, "false foo bar"}],
        verbose: true
      )

      assert capture_io(fn -> catch_exit(Run.run(["pre-commit"])) end) =~
               "pre_commit failed on `false foo bar`"
    end
  end

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

  describe "Given env vars to the mix git hook task" do
    test "when running a command the env vars are available" do
      env = [{"TEST", "test-value"}]

      put_git_hook_config(:pre_commit,
        tasks: [{:cmd, "env", env: env}],
        verbose: true
      )

      assert capture_io(fn -> Run.run(["pre-commit"]) end) =~ "test-value"
    end

    test "when running a file the env vars are available" do
      env = [{"TEST", "test-value"}]

      put_git_hook_config(:pre_commit,
        tasks: [{:file, "priv/test_script", env: env}],
        verbose: true
      )

      assert capture_io(fn -> Run.run(["pre-commit"]) end) =~ "test-value"
    end

    test "when the file returns exits with != 0 the hook exits with != 0" do
      env = [{"TEST", "test-value"}]

      put_git_hook_config(:pre_commit,
        tasks: [{:file, "priv/test_script_fail", env: env}],
        verbose: true
      )

      capture_io(fn ->
        # Run.run(["pre-commit"])
        assert catch_exit(Run.run(["pre-commit"])) == 1
      end) =~ "Failed"
    end
  end
end

defmodule GitHooks.Config.TasksTest do
  @moduledoc false

  use ExUnit.Case, async: false
  use GitHooks.TestSupport.ConfigCase

  alias GitHooks.Config.TasksConfig

  describe "tasks/1" do
    test "when it is all then all the configured hooks are run" do
      put_git_hook_config([:pre_commit, :pre_push], tasks: ["help", "help deps"])

      assert TasksConfig.tasks(:all) == {:all, ["help", "help deps", "help", "help deps"]}
    end

    test "when there are not configured mix tasks then an empty list is returned" do
      put_git_hook_config(:pre_commit, tasks: ["help", "help deps"])

      assert TasksConfig.tasks(:unknown_hook) == {:unknown_hook, []}
    end

    test "when there are configured mix tasks then a list of the mix tasks is returned" do
      tasks = ["help", "help deps"]

      put_git_hook_config(:pre_commit, tasks: tasks)

      assert TasksConfig.tasks(:pre_commit) == {:pre_commit, tasks}
    end
  end
end

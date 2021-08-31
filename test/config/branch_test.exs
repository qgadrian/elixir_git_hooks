defmodule GitHooks.Config.BranchTest do
  @moduledoc false

  use ExUnit.Case, async: false
  use GitHooks.TestSupport.ConfigCase

  alias GitHooks.Config.BranchConfig

  describe "current_branch_allowed?/0" do
    test "when current branch is allowed to run for the git hook then current_branch_allowed? function returns true" do
      Application.put_env(:git_hooks, :current_branch_fn, fn -> {"master\n", 0} end)
      branches_config = [whitelist: ["master"], blacklist: []]

      put_git_hook_config(:pre_commit, branches: branches_config)

      assert BranchConfig.current_branch_allowed?(:pre_commit)
    end

    test "when branches config is not provided then current_branch_allowed? function return true" do
      assert BranchConfig.current_branch_allowed?(:pre_commit)
    end

    test "when current branch is disallowed to run git hook then current_branch_allowed? function returns false" do
      Application.put_env(:git_hooks, :current_branch_fn, fn -> {"master\n", 0} end)
      branches_config = [whitelist: [], blacklist: ["master"]]

      put_git_hook_config(:pre_commit, branches: branches_config)

      refute BranchConfig.current_branch_allowed?(:pre_commit)
    end

    test "when current branch match regex built from branches config then current_branch_allowed? function returns true" do
      branches_config = [whitelist: ["master", "main", "featprefix-.*"], blacklist: ["wip-.*"]]

      put_git_hook_config(:pre_commit, branches: branches_config)

      Application.put_env(:git_hooks, :current_branch_fn, fn -> {"featprefix-123\n", 0} end)
      assert BranchConfig.current_branch_allowed?(:pre_commit)

      Application.put_env(:git_hooks, :current_branch_fn, fn -> {"wip-123\n", 0} end)
      refute BranchConfig.current_branch_allowed?(:pre_commit)

      Application.put_env(:git_hooks, :current_branch_fn, fn -> {"branch-not-on-lists\n", 0} end)
      assert BranchConfig.current_branch_allowed?(:pre_commit)
    end
  end
end

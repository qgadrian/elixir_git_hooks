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

  describe "default_current_git_branch_function/0" do
    test "old git" do
      Application.delete_env(:git_hooks, :current_branch_fn)

      Application.put_env(:git_hooks, :current_git_version_fn, fn ->
        {"git version 2.17.1\n", 0}
      end)

      Application.put_env(:git_hooks, :current_branch_fn_old, fn ->
        {"branch-with-old-git\n", 0}
      end)

      Application.put_env(:git_hooks, :current_branch_fn_new, fn ->
        raise "version check invalid"
      end)

      assert "branch-with-old-git" == BranchConfig.current_branch()
    end

    test "new git" do
      Application.delete_env(:git_hooks, :current_branch_fn)

      Application.put_env(:git_hooks, :current_git_version_fn, fn ->
        {"git version 2.22.1\n", 0}
      end)

      Application.put_env(:git_hooks, :current_branch_fn_old, fn ->
        raise "version check invalid"
      end)

      Application.put_env(:git_hooks, :current_branch_fn_new, fn ->
        {"branch-with-new-git\n", 0}
      end)

      assert "branch-with-new-git" == BranchConfig.current_branch()
    end
  end
end

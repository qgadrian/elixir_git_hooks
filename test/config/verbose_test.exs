defmodule GitHooks.Config.VerboseTest do
  @moduledoc false

  use ExUnit.Case, async: false
  use GitHooks.TestSupport.ConfigCase

  alias GitHooks.Config.VerboseConfig

  describe "verbose/0" do
    test "returns the generic verbose config" do
      Application.put_env(:git_hooks, :verbose, true)

      assert VerboseConfig.verbose?()
    end

    test "if there is no config the default verbose config is false" do
      Application.delete_env(:git_hooks, :verbose)

      refute VerboseConfig.verbose?()
    end
  end

  describe "verbose/1" do
    test "when the git hook is unknown then the verbose config function returns false" do
      put_git_hook_config(:pre_commit, verbose: true)

      assert VerboseConfig.verbose?(:unknown_hook) == false
    end

    test "when the verbose is enabled for the git hook then the verbose config function returns true" do
      put_git_hook_config(:pre_commit, verbose: true)

      assert VerboseConfig.verbose?(:pre_commit)
    end

    test "when the verbose is enabled globally then the verbose config function returns true" do
      Application.put_env(:git_hooks, :verbose, true)

      assert VerboseConfig.verbose?(:pre_commit)
    end

    test "when the verbose is true globally but false for a githook then the verbose config function returns false" do
      put_git_hook_config(:pre_commit, verbose: false)
      Application.put_env(:git_hooks, :verbose, true)

      refute VerboseConfig.verbose?(:pre_commit)
    end
  end
end

defmodule GitHooks.Config.IOTest do
  @moduledoc false

  use ExUnit.Case, async: false
  use GitHooks.TestSupport.ConfigCase

  alias GitHooks.Config.IOConfig

  describe "Given a git hook type" do
    test "when the verbose is enabled then a IO stream is returned" do
      put_git_hook_config([:pre_commit], verbose: true)

      assert IOConfig.io_stream(:pre_commit) == IO.stream(:stdio, :line)
    end

    test "when the verbose is disabled then an empty string is returned" do
      put_git_hook_config([:pre_commit, :pre_push], verbose: false)

      assert IOConfig.io_stream(:pre_commit) == ""
    end
  end
end

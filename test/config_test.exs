defmodule GitHooks.ConfigTest do
  @moduledoc false

  use ExUnit.Case, async: false
  use GitHooks.TestSupport.ConfigCase

  alias GitHooks.Config

  describe "Given a git hook type" do
    test "when there are no supported git hooks configured then an empty list is returned" do
      assert Config.git_hooks() == []
    end

    test "when request the git hooks types then a list of supported git hooks types is returned" do
      put_git_hook_config([:pre_commit, :pre_push])

      assert Config.git_hooks() == [:pre_commit, :pre_push]
    end
  end
end

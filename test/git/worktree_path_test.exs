defmodule GitHooks.Git.WorktreePathTest do
  @moduledoc """
  Regression tests for git worktree support (issue #236).

  These deliberately do not use `GitProjectCase`: they need a real initial
  commit before `git worktree add`, and they must run with `:project_path`
  unset so that `GitPath` actually resolves paths through git.
  """

  use ExUnit.Case, async: false

  alias GitHooks.Git.GitPath

  setup do
    # `GitPath` short-circuits to `:project_path` when set; make sure no other
    # test leaked it so we exercise the git-based resolution.
    previous_project_path = Application.get_env(:git_hooks, :project_path)
    Application.delete_env(:git_hooks, :project_path)

    base =
      System.tmp_dir!()
      |> Path.join("git_hooks_wt_#{System.unique_integer([:positive])}")
      |> canonical()

    # Main repo with a commit so `git worktree add` has a HEAD to branch from.
    main = Path.join(base, "main")
    File.mkdir_p!(main)
    git!(main, ["init", "--quiet"])
    git!(main, ["commit", "--allow-empty", "--quiet", "-m", "init"])

    # A linked worktree that lives next to the main repo.
    sibling = Path.join(base, "sibling")
    git!(main, ["worktree", "add", "--quiet", sibling, "-b", "feat"])

    # A linked worktree nested inside an *unrelated* repo (issue #236, mode 2).
    outer = Path.join(base, "outer")
    File.mkdir_p!(outer)
    git!(outer, ["init", "--quiet"])
    nested = Path.join(outer, "nested")
    git!(main, ["worktree", "add", "--quiet", nested, "-b", "feat2"])

    on_exit(fn ->
      File.rm_rf!(base)

      if previous_project_path do
        Application.put_env(:git_hooks, :project_path, previous_project_path)
      end
    end)

    {:ok, main: main, sibling: sibling, outer: outer, nested: nested}
  end

  describe "resolve_app_path/0" do
    test "resolves a linked worktree to its own root, not the main worktree", %{
      sibling: sibling,
      main: main
    } do
      File.cd!(sibling, fn ->
        assert GitPath.resolve_app_path() == sibling
        refute GitPath.resolve_app_path() == main
      end)
    end

    test "resolves a worktree nested in an unrelated repo to the worktree", %{
      nested: nested,
      outer: outer
    } do
      File.cd!(nested, fn ->
        assert GitPath.resolve_app_path() == nested
        refute GitPath.resolve_app_path() == outer
      end)
    end
  end

  describe "resolve_git_hooks_path/0" do
    test "points at the shared hooks directory of the main repo from a worktree", %{
      sibling: sibling,
      main: main
    } do
      File.cd!(sibling, fn ->
        assert GitPath.resolve_git_hooks_path() == Path.join(main, ".git/hooks")
      end)
    end
  end

  #
  # Helpers
  #

  defp git!(cd, args) do
    {output, exit_code} =
      System.cmd(
        "git",
        ["-c", "user.email=test@example.com", "-c", "user.name=test"] ++ args,
        cd: cd,
        stderr_to_stdout: true
      )

    assert exit_code == 0, "git #{Enum.join(args, " ")} failed:\n#{output}"

    output
  end

  # Resolves symlinks (e.g. macOS /var -> /private/var) so the paths we build
  # match what git reports.
  defp canonical(path) do
    File.mkdir_p!(path)
    File.cd!(path, fn -> File.cwd!() end)
  end
end

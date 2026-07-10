defmodule GitHooks.Git.GitPath do
  @moduledoc false

  @doc """
  Returns the absolute path to the project's root directory.
  """
  def resolve_app_path do
    case Application.get_env(:git_hooks, :project_path) do
      nil -> git_toplevel()
      path -> Path.expand(path)
    end
  end

  @doc """
  Returns the absolute `.git/hooks` path directory for the parent project.
  """
  def resolve_git_hooks_path do
    app_path = resolve_app_path()

    {git_hooks_path, 0} =
      System.cmd("git", ["rev-parse", "--git-path", "hooks"], cd: app_path)

    git_hooks_path
    |> String.trim()
    |> Path.expand(app_path)
  end

  @doc """
  Returns the path to a specific hook file within the `.git/hooks` directory.
  """
  def git_hooks_path_for(hook_name) do
    resolve_git_hooks_path()
    |> Path.join(hook_name)
    |> Path.expand()
  end

  #
  # Private helper functions
  #

  # Resolves the working tree root via git so it works inside worktrees, where
  # `.git` is a file rather than a directory (including worktrees nested in an
  # unrelated parent repo).
  defp git_toplevel do
    case System.cmd("git", ["rev-parse", "--show-toplevel"],
           cd: File.cwd!(),
           stderr_to_stdout: true
         ) do
      {path, 0} ->
        path
        |> String.trim()
        |> Path.expand()

      {output, _exit_code} ->
        raise "git_hooks: #{File.cwd!()} is not inside a git working tree.\n#{String.trim(output)}"
    end
  end
end

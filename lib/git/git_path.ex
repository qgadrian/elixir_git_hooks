defmodule GitHooks.Git.GitPath do
  @moduledoc false

  @doc """
  Returns the absolute path to the project's root directory.
  """
  def resolve_app_path do
    # Attempt to get the project path from the config,
    # otherwise find the git root by traversing upwards.
    Application.get_env(:git_hooks, :project_path) ||
      find_git_root(File.cwd!()) ||
      raise "Could not find .git directory from #{File.cwd!()}"
  end

  @doc """
  Returns the absolute `.git/hooks` path directory for the parent project.
  """
  def resolve_git_hooks_path do
    Path.join(resolve_git_dir(), "hooks")
  end

  @doc """
  Returns the path to a specific hook file within the `.git/hooks` directory.
  """
  def git_hooks_path_for(hook_name) do
    Path.join(resolve_git_hooks_path(), hook_name)
  end

  #
  # Private helper functions
  #

  # Returns the absolute `.git` directory path for the parent project.
  defp resolve_git_dir do
    {git_dir, 0} =
      System.cmd("git", ["rev-parse", "--git-dir"], cd: resolve_app_path())

    Path.expand(String.trim(git_dir), resolve_app_path())
  end

  # Recursively traverse upwards to find the .git directory
  defp find_git_root(path) do
    if File.dir?(Path.join(path, ".git")) do
      path
    else
      parent = Path.dirname(path)

      if parent == path do
        # Reached the root of the filesystem without finding .git
        nil
      else
        find_git_root(parent)
      end
    end
  end
end

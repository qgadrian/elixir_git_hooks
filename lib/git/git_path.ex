defmodule GitHooks.Git.GitPath do
  @moduledoc false

  alias GitHooks.Git

  @doc """
  Returns the absolute path to the project's root directory.
  """
  def resolve_app_path do
    project_path = Application.get_env(:git_hooks, :project_path)

    if project_path do
      Path.expand(project_path)
    else
      # Find the git root by traversing upwards
      find_git_root(File.cwd!()) ||
        raise "Could not find .git directory from #{File.cwd!()}"
    end
  end

  @doc """
  Returns the absolute `.git/hooks` path directory for the parent project.
  """
  def resolve_git_hooks_path do
    "hooks"
    |> resolve_git_path()
    |> Path.expand(resolve_app_path())
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

  # Resolves the absolute path to a directory within the `.git` directory
  defp resolve_git_path(dir) when is_binary(dir) and dir != "" do
    git_path =
      Git.git_version()
      |> Version.compare(Version.parse!("2.10.0"))
      |> case do
        :lt ->
          git_dir = resolve_git_dir()
          Path.join(git_dir, dir)

        _ ->
          {git_path, 0} =
            System.cmd("git", ["rev-parse", "--git-path", dir], cd: resolve_app_path())

          String.trim(git_path)
      end

    Path.expand(git_path, resolve_app_path())
  end

  defp resolve_git_path(_dir) do
    raise ArgumentError, "resolve_git_path/1 requires a non-empty directory argument"
  end

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

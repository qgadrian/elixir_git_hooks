defmodule GitHooks.Git.Path do
  @moduledoc false

  alias GitHooks.Git

  @doc false
  @spec resolve_git_hooks_path() :: any
  def resolve_git_hooks_path do
    resolve_git_path_based_on_git_version("hooks")
  end

  @doc false
  def resolve_app_path do
    repo_path =
      resolve_git_path_based_on_git_version()
      |> Path.dirname()

    Path.relative_to(File.cwd!(), repo_path)
  end

  @spec git_hooks_path_for(path :: String.t()) :: String.t()
  def git_hooks_path_for(path) do
    __MODULE__.resolve_git_hooks_path()
    |> Path.join("/#{path}")
    |> String.replace(~r/\/+/, "/")
  end

  #
  # Private functions
  #

  # https://stackoverflow.com/questions/10848191/git-submodule-commit-hooks
  #
  # For git >= 2.10+ => `git rev-parse --git-path hooks`
  # For git < 2.10+ => `git rev-parse --git-dir /hooks`
  #
  # This will support as well changes on the default /hooks path:
  # `git config core.hooksPath .myCustomGithooks/`

  @spec resolve_git_path_based_on_git_version(dir :: String.t()) :: String.t()
  defp resolve_git_path_based_on_git_version(dir \\ "") do
    Git.git_version()
    |> Version.compare(Version.parse!("2.10.0"))
    |> case do
      :lt ->
        {path, 0} = System.cmd("git", ["rev-parse", "--git-dir", dir])
        String.replace(path, "\n", "")

      _gt_or_eq ->
        {path, 0} = System.cmd("git", ["rev-parse", "--git-path", dir])
        String.replace(path, "\n", "")
    end
  end
end

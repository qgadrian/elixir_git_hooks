defmodule GitHooks.Git.Path do
  @moduledoc false

  alias GitHooks.Git

  @doc false
  @spec resolve_git_hooks_path() :: any
  def resolve_git_hooks_path do
    :git_hooks
    |> Application.get_env(:git_path)
    |> case do
      nil -> resolve_git_hooks_path_based_on_git_version()
      custom_path -> custom_path
    end
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
  # Git 2.10+
  # `git rev-parse --git-path hooks`
  # Pre Git 2.10+
  # `git rev-parse --git-dir /hooks`
  #
  # This will support as well changes on the default /hooks path
  # git config core.hooksPath .githooks/

  @spec resolve_git_hooks_path_based_on_git_version() :: String.t()
  defp resolve_git_hooks_path_based_on_git_version() do
    Git.git_version()
    |> Version.compare(Version.parse!("2.10.0"))
    |> case do
      :lt ->
        {path, 0} = System.cmd("git", ["rev-parse", "--git-dir", "hooks"])
        String.replace(path, "\n", "")

      _gt_or_eq ->
        {path, 0} = System.cmd("git", ["rev-parse", "--git-path", "hooks"])
        String.replace(path, "\n", "")
    end
  end
end

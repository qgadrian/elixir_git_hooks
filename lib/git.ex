defmodule GitHooks.Git do
  @moduledoc false

  @doc false
  @spec resolve_git_path() :: any
  def resolve_git_path do
    :git_hooks
    |> Application.get_env(:git_path)
    |> case do
      nil ->
        {path, 0} = System.cmd("git", ["rev-parse", "--git-path", "hooks"])
        String.replace(path, "\n", "")

      custom_path ->
        custom_path
    end
  end

  @spec git_hooks_path_for(path :: String.t()) :: String.t()
  def git_hooks_path_for(path) do
    __MODULE__.resolve_git_path()
    |> Path.join("/#{path}")
  end
end

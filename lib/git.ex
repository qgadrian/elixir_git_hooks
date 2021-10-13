defmodule GitHooks.Git do
  @moduledoc false

  alias Mix.Project

  @doc false
  @spec resolve_git_path() :: any
  def resolve_git_path do
    :git_hooks
    |> Application.get_env(:git_path)
    |> case do
      nil ->
        path = Path.join(Project.deps_path(), "/../.git")

        if File.dir?(path) do
          path
        else
          resolve_git_submodule_path(path)
        end

      custom_path ->
        custom_path
    end
  end

  @spec resolve_git_submodule_path(String.t()) :: any
  defp resolve_git_submodule_path(git_path) do
    with {:ok, contents} <- File.read(git_path),
         %{"dir" => submodule_dir} <- Regex.named_captures(~r/^gitdir:\s+(?<dir>.*)$/, contents) do
      Project.deps_path()
      |> Path.join("/../" <> submodule_dir)
    else
      _error ->
        raise "Error resolving git submodule path '#{git_path}'"
    end
  end
end

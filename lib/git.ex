defmodule GitHooks.Git do
  @moduledoc false

  alias Mix.Project

  @doc false
  @spec resolve_git_path() :: any
  def resolve_git_path,
    do: maybe_preconfigured(Application.get_env(:git_hooks, :git_path, :detect))

  def resolve_app_path do
    git_dir = maybe_preconfigured(Application.get_env(:git_hooks, :git_path, :detect))
    repo_dir = Path.dirname(git_dir)
    Path.relative_to(File.cwd!(), repo_dir)
  end

  @spec maybe_preconfigured(:detect | binary) :: Path.t() | no_return
  def maybe_preconfigured(:detect) do
    # if we can't figure out cwd, we can't do anything
    working_directory = working_dir(File.cwd!())

    case path_from_git(working_directory) do
      {:ok, path} ->
        path

      {:error, :no_system_git} ->
        use_legacy_configuration()
    end
  end

  def maybe_preconfigured(path) do
    if File.exists?(path) do
      path
    else
      # should this warn and try to detect?
      raise "failed to find #{path}"
    end
  end

  @spec use_legacy_configuration :: Path.t() | no_return
  def use_legacy_configuration do
    path = Path.join(Project.deps_path(), "/../.git")

    maybe_submodules(File.dir?(path), path)
  end

  @spec path_from_git(Path.t(), String.t()) :: {:ok, Path.t()} | {:error, :no_system_git}
  def path_from_git(wd, git \\ "git") do
    case System.find_executable(git) &&
           System.cmd(git, ["rev-parse", "--show-toplevel"], cd: wd) do
      {output, 0} ->
        # We assume git is correct about this path
        {:ok, Path.join(String.trim(output), ".git")}

      _ ->
        {:error, :no_system_git}
    end
  end

  defp maybe_submodules(true, path), do: resolve_git_submodule_path(path)

  defp maybe_submodules(false, path), do: path

  defp parent_basename(path), do: Path.basename(Path.dirname(path))

  @spec resolve_git_submodule_path(String.t()) :: Path.t() | no_return
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

  defp working_dir(path) do
    if parent_basename(path) == "deps" do
      Path.dirname(path)
    else
      path
    end
  end
end

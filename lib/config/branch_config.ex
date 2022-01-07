defmodule GitHooks.Config.BranchConfig do
  @moduledoc false

  alias GitHooks.Config

  @typep system_cmd_result :: {Collectable.t(), non_neg_integer()}

  @doc """
  Returns the current branch of user repo
  """
  @spec current_branch() :: String.t()
  def current_branch do
    current_branch_fn =
      Application.get_env(:git_hooks, :current_branch_fn, &default_current_git_branch_function/0)

    current_branch_fn.()
    |> Tuple.to_list()
    |> List.first()
    |> String.replace("\n", "")
  end

  @doc """
  Returns if the current branch is allowed to run git hooks based on `branches`
  config.
  """
  @spec current_branch_allowed?(atom) :: boolean()
  def current_branch_allowed?(git_hook_type) do
    branch = current_branch()

    branches_config = branches(git_hook_type)

    whitelist = Keyword.get(branches_config, :whitelist, [])
    blacklist = Keyword.get(branches_config, :blacklist, [])

    valid_branch?(branch, whitelist, blacklist)
  end

  @spec valid_branch?(String.t(), list(String.t()), list(String.t())) :: boolean()
  defp valid_branch?(_, [], []), do: true

  defp valid_branch?(branch, [_ | _] = whitelist, []) do
    regex = whitelist |> Enum.join("|") |> Regex.compile!()

    Regex.match?(regex, branch)
  end

  defp valid_branch?(branch, [], [_ | _] = blacklist) do
    regex = blacklist |> Enum.join("|") |> Regex.compile!()

    not Regex.match?(regex, branch)
  end

  defp valid_branch?(branch, whitelist, blacklist) do
    valid_branch?(branch, whitelist, []) or valid_branch?(branch, [], blacklist)
  end

  @spec branches() :: Keyword.t()
  defp branches do
    Application.get_env(:git_hooks, :branches, [])
  end

  @spec branches(atom) :: Keyword.t()
  defp branches(git_hook_type) do
    git_hook_type
    |> Config.get_git_hook_type_config()
    |> Keyword.get_lazy(:branches, fn -> branches() end)
  end

  @spec default_current_git_branch_function() :: system_cmd_result
  defp default_current_git_branch_function do
    case get_git_version() do
      {:ok, git_version_output} ->
        determine_branch_command(git_version_output)

      _ ->
        raise "Git not found"
    end
  end

  @spec determine_branch_command(binary) :: system_cmd_result
  defp determine_branch_command(git_version_output) do
    case parse_git_version(git_version_output) do
      {mayor, minor} when mayor in [0, 1] or (mayor == 2 and minor < 22) ->
        Application.get_env(:git_hooks, :current_branch_fn_old, fn ->
          System.cmd("git", ["rev-parse", "--abbrev-ref", "HEAD"])
        end).()

      _ ->
        Application.get_env(:git_hooks, :current_branch_fn_new, fn ->
          System.cmd("git", ["branch", "--show-current"])
        end).()
    end
  end

  @spec get_git_version() :: {:ok, binary} | {:error, :invalid_git_version}
  defp get_git_version do
    case Application.get_env(:git_hooks, :current_git_version_fn, fn ->
           System.cmd("git", ["version"])
         end).() do
      {version, 0} ->
        {:ok, version}

      _ ->
        {:error, :invalid_git_version}
    end
  end

  @spec parse_git_version(binary) :: {integer, integer}
  defp parse_git_version("git version " <> git_output) do
    git_output
    |> String.split(".")
    |> Enum.take(2)
    |> Enum.map(&String.to_integer/1)
    |> List.to_tuple()
  end
end

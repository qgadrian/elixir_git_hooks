defmodule GitHooks.Config.BranchConfig do
  @moduledoc false

  alias GitHooks.Config

  @doc """
  Returns the current branch of user repo
  """
  @spec current_branch() :: String.t()
  def current_branch do
    current_branch_fn =
      Application.get_env(:git_hooks, :current_branch_fn, fn ->
        System.cmd("git", ["branch", "--show-current"])
      end)

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
end

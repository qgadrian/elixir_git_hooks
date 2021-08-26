defmodule GitHooks.Config do
  @moduledoc false

  @supported_hooks [
    :pre_commit,
    :prepare_commit_msg,
    :commit_msg,
    :post_commit,
    :pre_rebase,
    :pre_receive,
    :post_receive,
    :post_checkout,
    :post_merge,
    :pre_push,
    :push_to_checkout,
    :pre_applypatch,
    :applypatch_msg,
    :post_applypatch,
    :update,
    :post_update,
    :pre_auto_gc,
    :post_rewrite,
    :sendemail_validate,
    :fsmonitor_watchman
  ]

  @spec supported_hooks() :: list(atom)
  def supported_hooks, do: @supported_hooks ++ [:all]

  @spec git_hooks() :: list(atom)
  def git_hooks do
    :git_hooks
    |> Application.get_env(:hooks, [])
    |> Keyword.take(@supported_hooks)
    |> Keyword.keys()
  end

  @spec tasks(atom) :: {atom, list(String.t())}
  def tasks(git_hook_type)

  def tasks(:all = git_hook_type) do
    tasks =
      :git_hooks
      |> Application.get_env(:hooks, [])
      |> Enum.reduce([], fn {_hook_type, hook_config}, acc ->
        hook_tasks = Keyword.get(hook_config, :tasks, [])
        acc ++ hook_tasks
      end)

    {git_hook_type, tasks}
  end

  def tasks(git_hook_type) do
    tasks =
      :git_hooks
      |> Application.get_env(:hooks, [])
      |> Keyword.get(git_hook_type, [])
      |> Keyword.get(:tasks, [])

    {git_hook_type, tasks}
  end

  @doc """
  Returns the configured mix path.

  The config should be a valid path the `mix` binary. The default behaviour
  expects a regular `elixir` install and defaults to `mix`.
  """
  @spec mix_path() :: String.t()
  def mix_path do
    Application.get_env(:git_hooks, :mix_path, "mix")
  end

  @doc """
  Returns the general verbose configuration.
  """
  @spec verbose?() :: boolean()
  def verbose? do
    Application.get_env(:git_hooks, :verbose, false)
  end

  @doc """
  Returns the verbose configuration for the git hooks, with a fallback for the
  general one.
  """
  @spec verbose?(atom) :: boolean()
  def verbose?(git_hook_type) do
    git_hook_type
    |> get_git_hook_type_config()
    |> Keyword.get_lazy(:verbose, fn -> verbose?() end)
  end

  @doc """
  Returns if the current branch is allowed to run git hooks based on `branches`
  config.
  """
  @spec current_branch_allowed?(atom) :: boolean()
  def current_branch_allowed?(git_hook_type) do
    case branches(git_hook_type) do
      [whitelist: [], blacklist: []] ->
        true

      [whitelist: whitelist, blacklist: blacklist] ->
        branch = current_branch()

        branch in whitelist or branch not in blacklist
    end
  end

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

  @spec branches() :: Keyword.t()
  defp branches do
    Keyword.merge([whitelist: [], blacklist: []], Application.get_env(:git_hooks, :branches, []))
  end

  @spec branches(atom) :: Keyword.t()
  defp branches(git_hook_type) do
    git_hook_type
    |> get_git_hook_type_config()
    |> Keyword.get_lazy(:branches, fn -> branches() end)
  end

  defp get_git_hook_type_config(git_hook_type) do
    :git_hooks
    |> Application.get_env(:hooks, [])
    |> Keyword.get(git_hook_type, [])
  end

  @spec io_stream(atom) :: any()
  def io_stream(git_hook_type) do
    case verbose?(git_hook_type) do
      true -> IO.stream(:stdio, :line)
      _ -> ""
    end
  end
end

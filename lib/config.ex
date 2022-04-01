defmodule GitHooks.Config do
  @moduledoc false

  alias GitHooks.Config.{
    BranchConfig,
    IOConfig,
    TasksConfig,
    VerboseConfig
  }

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

  @doc """
  Returns the configuration for the given git hook type.
  """
  @spec get_git_hook_type_config(GitHooks.git_hook_type()) :: list(term)
  def get_git_hook_type_config(git_hook_type) do
    :git_hooks
    |> Application.get_env(:hooks, [])
    |> Keyword.get(git_hook_type, [])
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
  Returns the configuration for additional success returns from mix
  tasks.

  See `GitHooks.Task` for default supported returns from Mix task.
  """
  @spec extra_success_returns() :: list(term)
  def extra_success_returns do
    Application.get_env(:git_hooks, :extra_success_returns, [])
  end

  defdelegate tasks(git_hook_type), to: TasksConfig

  defdelegate verbose?, to: VerboseConfig
  defdelegate verbose?(git_hook_type), to: VerboseConfig

  defdelegate current_branch_allowed?(git_hook_type), to: BranchConfig
  defdelegate current_branch, to: BranchConfig

  defdelegate io_stream(git_hook_type), to: IOConfig
end

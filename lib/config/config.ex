defmodule GitHooks.Config do
  @moduledoc false

  @supported_hooks [
    :pre_commit,
    :pre_push,
    :pre_rebase,
    :pre_receive,
    :pre_applypatch,
    :post_update
  ]

  @spec supported_hooks() :: list(atom())
  def supported_hooks, do: @supported_hooks

  @spec git_hooks() :: list(atom())
  def git_hooks do
    :git_hooks
    |> Application.get_env(:git_hooks, [])
    |> Keyword.take(@supported_hooks)
    |> Keyword.keys()
  end

  @spec mix_tasks(atom()) :: list(String.t())
  def mix_tasks(git_hook_type) do
    :git_hooks
    |> Application.get_env(:git_hooks, [])
    |> Keyword.get(git_hook_type, [])
    |> Keyword.get(:mix_tasks, [])
  end

  @spec verbose?(atom()) :: boolean()
  def verbose?(git_hook_type) do
    :git_hooks
    |> Application.get_env(:git_hooks, [])
    |> Keyword.get(git_hook_type, [])
    |> Keyword.get(:verbose, Application.get_env(:git_hooks, :verbose, false))
  end

  @spec io_stream(atom()) :: any()
  def io_stream(git_hook_type) do
    case verbose?(git_hook_type) do
      true ->
        IO.stream(:stdio, :line)

      _ ->
        ""
    end
  end
end

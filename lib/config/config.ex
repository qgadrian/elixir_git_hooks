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

  @spec mix_tasks(atom) :: list(String.t())
  def mix_tasks(git_hook_type)

  def mix_tasks(:all = git_hook_type) do
    mix_tasks =
      :git_hooks
      |> Application.get_env(:hooks, [])
      |> Enum.reduce([], fn {_hook_type, hook_config}, acc ->
        hook_mix_tasks = Keyword.get(hook_config, :mix_tasks, [])
        acc ++ hook_mix_tasks
      end)

    {git_hook_type, mix_tasks}
  end

  def mix_tasks(git_hook_type) do
    mix_tasks =
      :git_hooks
      |> Application.get_env(:hooks, [])
      |> Keyword.get(git_hook_type, [])
      |> Keyword.get(:mix_tasks, [])

    {git_hook_type, mix_tasks}
  end

  @spec verbose?(atom) :: boolean()
  def verbose?(git_hook_type) do
    :git_hooks
    |> Application.get_env(:hooks, [])
    |> Keyword.get(git_hook_type, [])
    |> Keyword.get(:verbose, Application.get_env(:git_hooks, :verbose, false))
  end

  @spec io_stream(atom) :: any()
  def io_stream(git_hook_type) do
    case verbose?(git_hook_type) do
      true ->
        IO.stream(:stdio, :line)

      _ ->
        ""
    end
  end
end

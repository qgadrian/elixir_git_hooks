defmodule GitHooks.TestSupport.ConfigCase do
  @moduledoc """
  This module provides a function to setup a git hook configuracion for the application.
  """

  use ExUnit.CaseTemplate

  using do
    quote do
      @default_verbose false
      @default_mix_tasks ["mix help", "mix help deps"]

      setup do
        on_exit(fn ->
          cleanup_config()
        end)
      end

      @spec cleanup_config() :: :ok
      def cleanup_config do
        Application.delete_env(:git_hooks, :hooks)
        Application.delete_env(:git_hooks, :verbose)
      end

      @spec put_git_hook_config(list(atom) | atom, keyword) :: :ok
      def put_git_hook_config(git_hook_type_or_types, opts \\ [])

      def put_git_hook_config(git_hook_types, opts) when is_list(git_hook_types) do
        git_hook_config = [
          verbose: opts[:verbose] || @default_verbose,
          tasks: opts[:tasks] || @default_mix_tasks
        ]

        git_hook_configuration =
          git_hook_types
          |> Enum.map(&{&1, git_hook_config})
          |> Keyword.new()

        Application.put_env(:git_hooks, :hooks, git_hook_configuration)
      end

      def put_git_hook_config(git_hook_type, opts) do
        git_hook_config = [
          verbose: opts[:verbose] || @default_verbose,
          tasks: opts[:tasks] || @default_mix_tasks
        ]

        git_hook_configuration = Keyword.new([{git_hook_type, git_hook_config}])

        Application.put_env(:git_hooks, :hooks, git_hook_configuration)
      end
    end
  end
end

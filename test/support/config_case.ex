defmodule GitHooks.TestSupport.ConfigCase do
  @moduledoc """
  This module provides a function to setup a git hook configuracion for the application.
  """

  use ExUnit.CaseTemplate

  using do
    quote do
      @default_verbose false
      @default_mix_tasks ["help", "help deps"]

      setup do
        on_exit(fn ->
          cleanup_config()
        end)
      end

      @spec cleanup_config() :: :ok
      def cleanup_config do
        Application.delete_env(:git_hooks, :git_hooks)
        Application.delete_env(:git_hooks, :verbose)
      end

      @spec put_git_hook_config(atom(), Keyword.t()) :: :ok
      def put_git_hook_config(git_hook_type, opts \\ []) do
        git_hook_config = [
          verbose: opts[:verbose] || @default_verbose,
          mix_tasks: opts[:mix_tasks] || @default_mix_tasks
        ]

        git_hook_configuration = Keyword.new([{git_hook_type, git_hook_config}])

        Application.put_env(:git_hooks, :git_hooks, git_hook_configuration)
      end

      @spec put_git_hook_configs(list(atom()), Keyword.t()) :: :ok
      def put_git_hook_configs(git_hook_types, opts \\ []) do
        git_hook_config = [
          verbose: opts[:verbose] || @default_verbose,
          mix_tasks: opts[:mix_tasks] || @default_mix_tasks
        ]

        git_hook_configuration =
          git_hook_types
          |> Enum.map(&{&1, git_hook_config})
          |> Keyword.new()

        Application.put_env(:git_hooks, :git_hooks, git_hook_configuration)
      end
    end
  end
end

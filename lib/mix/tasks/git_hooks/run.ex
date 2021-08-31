defmodule Mix.Tasks.GitHooks.Run do
  @shortdoc "Runs all the configured mix tasks for a given git hook."

  @moduledoc """
  Runs all the configured mix tasks for a given git hook.

  Any [git hook](https://git-scm.com/docs/githooks) is supported.

  ## Examples

  You can run any hook by running `mix git_hooks.run hook_name`. For example:

  ```elixir
  mix git_hooks.run pre_commit
  ```

  You can also all the hooks which are configured with `mix git_hooks.run all`.
  """

  use Mix.Task

  alias GitHooks.Config
  alias GitHooks.Printer

  @typedoc """
  Run options:

  * `include_hook_args`: Whether the git hook args should be sent to the
  command to be executed. In case of `true`, the args will be amended to the
  command. Defaults to `false`.
  """
  @type run_opts :: [
          {:include_hook_args, String.t()},
          {:env, list({String.t(), binary})}
        ]

  @doc """
  Runs a task for a given git hook.

  The task can be one of three different types:

  * `{:cmd, "command arg1 arg2"}`: Runs a command.
  * `{:file, "path_to_file"}`: Runs an executable file.
  * `"command arg1 arg2"`: Runs a simple command, supports no options.

  The first two options above can use a third element in the tuple, see
  [here](`t:run_opts/0`) more info about the options.
  """
  @impl true
  @spec run(list(String.t())) :: :ok | no_return()
  def run([]), do: error_exit()

  def run(args) do
    {[git_hook_name], args} = Enum.split(args, 1)

    git_hook_type =
      git_hook_name
      |> get_atom_from_arg()
      |> check_is_valid_git_hook!()

    if Config.current_branch_allowed?(git_hook_type) do
      git_hook_type
      |> Printer.info("Running hooks for ", append_first_arg: true)
      |> Config.tasks()
      |> run_tasks(args)
    else
      Printer.info("skipping git_hooks for #{Config.current_branch()} branch")
    end
  end

  @spec run_tasks({atom, list(GitHooks.allowed_configs())}, GitHooks.git_hook_args()) ::
          :ok | no_return
  defp run_tasks({git_hook_type, tasks}, git_hook_args) do
    Enum.each(tasks, &run_task(&1, git_hook_type, git_hook_args))
  end

  @spec run_task(GitHooks.allowed_configs(), GitHooks.git_hook_type(), GitHooks.git_hook_args()) ::
          :ok | no_return
  defp run_task(task_config, git_hook_type, git_hook_args) do
    task_config
    |> GitHooks.new_task(git_hook_type, git_hook_args)
    |> GitHooks.Task.run()
    |> GitHooks.Task.print_result()
    |> GitHooks.Task.success?()
    |> exit_if_failed()
  end

  @spec get_atom_from_arg(String.t()) :: atom | no_return
  defp get_atom_from_arg(git_hook_type_arg) do
    case git_hook_type_arg do
      nil ->
        Printer.error("You should provide a git hook type to run")
        error_exit()

      git_hook_type ->
        git_hook_type
        |> Recase.to_snake()
        |> String.to_atom()
    end
  end

  @spec check_is_valid_git_hook!(atom) :: atom | no_return
  defp check_is_valid_git_hook!(git_hook_type) do
    unless Enum.any?(Config.supported_hooks(), &(&1 == git_hook_type)) do
      Printer.error("Invalid or unsupported hook `#{git_hook_type}`")
      Printer.warn("Supported hooks are: #{inspect(Config.supported_hooks())}")
      error_exit()
    end

    git_hook_type
  end

  @spec exit_if_failed(is_success :: boolean) :: :ok | no_return
  defp exit_if_failed(true), do: :ok
  defp exit_if_failed(false), do: error_exit()

  @spec error_exit(term) :: no_return
  @dialyzer {:no_return, error_exit: 0}
  defp error_exit(error_code \\ {:shutdown, 1}), do: exit(error_code)
end

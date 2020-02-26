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

  @opaque git_hook_args :: list(String.t())

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
  @spec run(list(String.t())) :: :ok | no_return
  def run([]), do: error_exit()

  def run(args) do
    {[git_hook_name], args} = Enum.split(args, 1)

    git_hook_name
    |> get_atom_from_arg()
    |> check_is_valid_git_hook!()
    |> Printer.info("Running hooks for ", append_first_arg: true)
    |> Config.tasks()
    |> run_tasks(args)
    |> success_exit()
  end

  @spec run_tasks({atom, list(String.t())}, git_hook_args()) :: :ok
  defp run_tasks({git_hook_type, tasks}, git_hook_args) do
    Enum.each(tasks, &run_task(&1, git_hook_type, git_hook_args))
  end

  @spec run_task(String.t(), atom, git_hook_args()) :: :ok | no_return
  @spec run_task({:file, String.t(), run_opts()}, atom, git_hook_args()) :: :ok | no_return
  @spec run_task({:cmd, String.t(), run_opts()}, atom, git_hook_args()) :: :ok | no_return
  defp run_task({:file, script_file}, git_hook_type, git_hook_args) do
    run_task({:file, script_file, []}, git_hook_type, git_hook_args)
  end

  defp run_task({:file, script_file, opts}, git_hook_type, git_hook_args) do
    env_vars = Keyword.get(opts, :env, [])

    args =
      if Keyword.get(opts, :include_hook_args, false) do
        git_hook_args
      else
        []
      end

    script_file
    |> Path.absname()
    |> System.cmd(
      args,
      into: Config.io_stream(git_hook_type),
      env: env_vars
    )
    |> case do
      {_result, 0} ->
        Printer.success("`#{script_file}` was successful")

      {result, _} ->
        if !Config.verbose?(git_hook_type), do: IO.puts(result)

        Printer.error("`#{script_file}` execution failed")
        error_exit()
    end
  end

  defp run_task({:cmd, command}, git_hook_type, git_hook_args) do
    run_task({:cmd, command, []}, git_hook_type, git_hook_args)
  end

  defp run_task({:cmd, command, opts}, git_hook_type, git_hook_args) when is_list(opts) do
    [base_command | args] = String.split(command, " ")

    env_vars = Keyword.get(opts, :env, [])

    command_args =
      if Keyword.get(opts, :include_hook_args, false) do
        Enum.concat(args, git_hook_args)
      else
        args
      end

    base_command
    |> System.cmd(
      command_args,
      into: Config.io_stream(git_hook_type),
      env: env_vars
    )
    |> case do
      {_result, 0} ->
        Printer.success("`#{command}` was successful")

      {result, _} ->
        if !Config.verbose?(git_hook_type), do: IO.puts(result)

        Printer.error("#{Atom.to_string(git_hook_type)} failed on `#{command}`")
        error_exit()
    end
  rescue
    error ->
      Printer.error("Error executing the command: #{inspect(error)}")
      error_exit()
  end

  defp run_task(command, git_hook_type, git_hook_args) when is_binary(command) do
    run_task({:cmd, command, []}, git_hook_type, git_hook_args)
  end

  defp run_task(task, git_hook_type, _git_hook_args),
    do:
      raise("""
      Invalid task #{inspect(task)} for hook #{inspect(git_hook_type)}", only String, {:file, ""} or {:cmd, ""} are supported.
      """)

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

  @spec check_is_valid_git_hook!(atom) :: no_return
  defp check_is_valid_git_hook!(git_hook_type) do
    unless Enum.any?(Config.supported_hooks(), &(&1 == git_hook_type)) do
      Printer.error("Invalid or unsupported hook `#{git_hook_type}`")
      Printer.warn("Supported hooks are: #{inspect(Config.supported_hooks())}")
      error_exit()
    end

    git_hook_type
  end

  @spec success_exit(any) :: :ok
  defp success_exit(_), do: :ok

  @spec error_exit(non_neg_integer) :: no_return
  defp error_exit(error_code \\ 1), do: exit(error_code)
end

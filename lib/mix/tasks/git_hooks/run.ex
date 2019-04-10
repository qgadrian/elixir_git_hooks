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

  @impl true
  @spec run(list(String.t())) :: :ok | no_return
  def run(args) do
    args
    |> List.first()
    |> get_atom_from_arg()
    |> check_is_valid_git_hook!()
    |> Printer.info("Running hooks for ", append_first_arg: true)
    |> Config.tasks()
    |> run_tasks()
    |> success_exit()
  end

  @spec run_tasks({atom, list(String.t())}) :: :ok
  defp run_tasks({git_hook_type, tasks}) do
    Enum.each(tasks, &run_task(&1, git_hook_type))
  end

  @spec run_task(String.t(), atom) :: :ok | no_return
  defp run_task(task, git_hook_type) do
    [command | args] = String.split(task, " ")

    command
    |> System.cmd(
      args,
      stderr_to_stdout: true,
      into: Config.io_stream(git_hook_type)
    )
    |> case do
      {_result, 0} ->
        Printer.success("`#{task}` was successful")

      {result, _} ->
        if !Config.verbose?(git_hook_type), do: IO.puts(result)

        Printer.error("#{Atom.to_string(git_hook_type)} failed on `#{task}`")
        error_exit()
    end
  rescue
    error ->
      Printer.error("Error executing the command: #{inspect(error)}")
      error_exit()
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

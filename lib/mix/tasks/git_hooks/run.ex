defmodule Mix.Tasks.GitHooks.Run do
  @moduledoc """
  Module that defines the a git hook that will the configured mix tasks .

  The task will exepect an argument that will determine which git hook to run.

  The supported git hooks are:
    * pre_commit
    * pre_push
    * pre_rebase
    * pre_receive
    * pre_applypatch
    * post_update
  """

  @shortdoc "Module that defines a git hook that will run the configured mix tasks."

  use Mix.Task

  alias GitHooks.Config
  alias GitHooks.Printer

  @impl true
  def run(args) do
    git_hook_type =
      args
      |> List.first()
      |> get_atom_from_arg()
      |> check_is_valid_git_hook!()

    Printer.info("Running hooks for #{git_hook_type}")

    git_hook_type
    |> Config.mix_tasks()
    |> Enum.each(&run_commands(&1, git_hook_type))
    |> success_exit()
  end

  @spec run_commands(String.t(), atom()) :: :ok | no_return
  defp run_commands(mix_task, git_hook_type) do
    "mix"
    |> System.cmd(
      String.split(mix_task, " "),
      stderr_to_stdout: true,
      into: Config.io_stream(git_hook_type)
    )
    |> case do
      {_result, 0} ->
        Printer.success("`mix #{mix_task}` was successful")

      {result, _} ->
        if !Config.verbose?(git_hook_type), do: IO.puts(result)

        Printer.error("#{Atom.to_string(git_hook_type)} failed on `mix #{mix_task}`")
        error_exit()
    end
  end

  @spec get_atom_from_arg(String.t()) :: atom() | no_return
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

  @spec check_is_valid_git_hook!(atom()) :: no_return
  defp check_is_valid_git_hook!(git_hook_type) do
    unless Enum.any?(Config.supported_hooks(), &(&1 == git_hook_type)) do
      Printer.error("Invalid or unsupported hook `#{git_hook_type}`")
      Printer.warn("Supported hooks are: #{inspect(Config.supported_hooks())}")
      error_exit()
    end

    git_hook_type
  end

  @spec success_exit(any()) :: :ok
  defp success_exit(_), do: :ok

  @spec error_exit(non_neg_integer) :: no_return
  defp error_exit(error_code \\ 1), do: exit(error_code)
end

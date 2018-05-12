defmodule Mix.Tasks.GitHooks.Run do
  @shortdoc "Runs all the configured mix tasks for a given git hook."

  @moduledoc """
  Runs all the configured mix tasks for a given git hook.

  Any [git hook](https://git-scm.com/docs/githooks) is supported.

  For example, to run the `pre_commit` hook tasks run:

    `mix git_hooks.run pre_commit`

  Or you can also all the configured hooks with:

    `mix git_hooks.run all`
  """

  use Mix.Task

  alias GitHooks.Config
  alias GitHooks.Printer

  @impl true
  def run(args) do
    args
    |> List.first()
    |> get_atom_from_arg()
    |> check_is_valid_git_hook!()
    |> Printer.info("Running hooks for ", append_first_arg: true)
    |> Config.mix_tasks()
    |> run_mix_tasks()
    |> success_exit()
  end

  @spec run_mix_tasks({atom, list(String.t())}) :: any
  defp run_mix_tasks({git_hook_type, mix_tasks}) do
    Enum.each(mix_tasks, &run_mix_task(&1, git_hook_type))
  end

  @spec run_mix_task(String.t(), atom) :: :ok | no_return
  defp run_mix_task(mix_task, git_hook_type) do
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

  @spec success_exit(any()) :: :ok
  defp success_exit(_), do: :ok

  @spec error_exit(non_neg_integer) :: no_return
  defp error_exit(error_code \\ 1), do: exit(error_code)
end

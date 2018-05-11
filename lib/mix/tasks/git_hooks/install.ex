defmodule Mix.Tasks.GitHooks.Install do
  @shortdoc "Installs the configured git hooks backing up the previous files."

  @moduledoc """
  Installs the configured git hooks.

  Before installing the new hooks, the already hooks files are backed up
  with the extension `.pre_git_hooks_backup`.

  ## Command line options
    * `--quiet` - disables the output of the files that are beeing copied/backed up

  To manually install the git hooks run:

    `mix git_hooks.install`
  """

  use Mix.Task

  alias GitHooks.Config
  alias Mix.Project
  alias GitHooks.Printer

  @impl true
  def run(args) do
    {opts, _other_args, _} =
      OptionParser.parse(args, switches: [quiet: :boolean], aliases: [q: :quiet])

    install(opts)

    :ok
  end

  @spec install(Keyword.t()) :: any()
  defp install(opts) do
    template_file =
      :git_hooks
      |> :code.priv_dir()
      |> Path.join("/hook_template")

    Config.git_hooks()
    |> Enum.each(fn git_hook ->
      git_hook_atom_as_string = Atom.to_string(git_hook)
      git_hook_atom_as_kebab_string = Recase.to_kebab(git_hook_atom_as_string)

      case File.read(template_file) do
        {:ok, body} ->
          target_file_path =
            Project.deps_path()
            |> Path.join("/../.git/hooks/#{git_hook_atom_as_kebab_string}")

          target_file_body =
            String.replace(body, "$git_hook", git_hook_atom_as_string, global: true)

          unless opts[:quiet] do
            Printer.warn(
              "Writing git hook for `#{git_hook_atom_as_string}` to `#{target_file_path}`"
            )
          end

          backup_current_hook(git_hook_atom_as_kebab_string, opts)

          File.write(target_file_path, target_file_body)
          File.chmod(target_file_path, 0o755)

        {:error, reason} ->
          reason |> inspect() |> Printer.error()
      end
    end)

    :ok
  end

  @spec backup_current_hook(String.t(), Keyword.t()) :: {:error, atom} | {:ok, non_neg_integer()}
  defp backup_current_hook(git_hook_to_backup, opts) do
    source_file_path =
      Project.deps_path()
      |> Path.join("/../.git/hooks/#{git_hook_to_backup}")

    target_file_path =
      Project.deps_path()
      |> Path.join("/../.git/hooks/#{git_hook_to_backup}.pre_git_hooks_backup")

    unless opts[:quiet] do
      Printer.warn("Backing up git hook file `#{source_file_path}` to `#{target_file_path}`")
    end

    File.copy(source_file_path, target_file_path)
  end
end

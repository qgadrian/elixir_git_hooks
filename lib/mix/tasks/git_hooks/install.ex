defmodule Mix.Tasks.GitHooks.Install do
  @moduledoc """
  This module installs the configured git hooks.
  """

  @shortdoc "This module install the configured git hooks."

  use Mix.Task

  alias GitHooks.Config
  alias Mix.Project
  alias GitHooks.Printer

  @impl true
  def run(_args) do
    install()

    :ok
  end

  @spec install(Keyword.t()) :: any()
  def install(opts \\ []) do
    # Project.deps_path()
    # |> Path.join("/git_hooks/priv/hook_template")
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

          backup_current_hook(git_hook_atom_as_kebab_string)

          File.write(target_file_path, target_file_body)
          File.chmod(target_file_path, 0o755)

        {:error, reason} ->
          reason |> inspect() |> Printer.error()
      end
    end)

    :ok
  end

  @spec backup_current_hook(String.t()) :: {:error, atom()} | {:ok, non_neg_integer()}
  def backup_current_hook(git_hook_to_backup) do
    source_file_path =
      Project.deps_path()
      |> Path.join("/../.git/hooks/#{git_hook_to_backup}")

    target_file_path =
      Project.deps_path()
      |> Path.join("/../.git/hooks/#{git_hook_to_backup}.pre_git_hooks_backup")

    File.copy(source_file_path, target_file_path)
  end
end

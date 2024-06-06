defmodule Mix.Tasks.GitHooks.Install do
  @shortdoc "Installs the configured git hooks backing up the previous files."

  @moduledoc """
  Installs the configured git hooks.

  Before installing the new hooks, the already hooks files are backed up
  with the extension `.pre_git_hooks_backup`.

  ## Command line options
    * `--quiet` - disables the output of the files that are being copied/backed up

  To manually install the git hooks run:

  ```elixir
  mix git_hooks.install`
  ```
  """

  use Mix.Task

  alias GitHooks.Config
  alias GitHooks.Git.Path, as: GitPath
  alias GitHooks.Printer

  @impl true
  @spec run(Keyword.t()) :: :ok
  def run(args) do
    {opts, _other_args, _} =
      OptionParser.parse(args,
        switches: [quiet: :boolean, dry_run: :boolean],
        aliases: [q: :quiet]
      )

    install(opts)
  end

  @spec install(Keyword.t()) :: any()
  defp install(opts) do
    template_file =
      :git_hooks
      |> :code.priv_dir()
      |> Path.join("/hook_template")

    Printer.info("Installing git hooks...")

    mix_path = Config.mix_path()
    project_path = Application.get_env(:git_hooks, :project_path, "")

    ensure_hooks_folder_exists()
    clean_missing_hooks()
    track_configured_hooks()

    git_hooks_configs = Config.git_hooks()

    install_result =
      Enum.map(git_hooks_configs, fn git_hook ->
        git_hook_atom_as_string = Atom.to_string(git_hook)
        git_hook_atom_as_kebab_string = Recase.to_kebab(git_hook_atom_as_string)

        case File.read(template_file) do
          {:ok, body} ->
            target_file_path = GitPath.git_hooks_path_for(git_hook_atom_as_kebab_string)

            unless opts[:quiet] || !Config.verbose?() do
              Printer.info("Installed git hook: #{target_file_path}")
            end

            target_file_body =
              body
              |> String.replace("$git_hook", git_hook_atom_as_string)
              |> String.replace("$mix_path", mix_path)
              |> String.replace("$project_path", project_path)

            unless opts[:quiet] || !Config.verbose?() do
              Printer.info(
                "Writing git hook for `#{git_hook_atom_as_string}` to `#{target_file_path}`"
              )
            end

            backup_current_hook(git_hook_atom_as_kebab_string, opts)

            if opts[:dry_run] do
              {git_hook, target_file_body}
            else
              File.write(target_file_path, target_file_body)
              File.chmod(target_file_path, 0o755)
            end

          {:error, reason} ->
            reason |> inspect() |> Printer.error()
        end
      end)

    if opts[:dry_run] do
      install_result
    else
      :ok
    end
  end

  @spec backup_current_hook(String.t(), Keyword.t()) :: {:error, atom} | {:ok, non_neg_integer()}
  defp backup_current_hook(git_hook_to_backup, opts) do
    source_file_path = GitPath.git_hooks_path_for(git_hook_to_backup)

    target_file_path = GitPath.git_hooks_path_for("/#{git_hook_to_backup}.pre_git_hooks_backup")

    unless opts[:quiet] || !Config.verbose?() do
      Printer.info("Backing up git hook file `#{source_file_path}` to `#{target_file_path}`")
    end

    File.copy(source_file_path, target_file_path)
  end

  @spec track_configured_hooks() :: any
  defp track_configured_hooks do
    git_hooks = Config.git_hooks() |> Enum.join(" ")

    "/git_hooks.db"
    |> GitPath.git_hooks_path_for()
    |> write_backup(git_hooks)
  end

  @spec write_backup(String.t(), String.t()) :: any
  defp write_backup(file_path, git_hooks) do
    file_path
    |> File.open!([:write])
    |> IO.binwrite(git_hooks)
  rescue
    error ->
      Printer.warn(
        "Couldn't find git_hooks.db file, won't be able to restore old backups: #{inspect(error)}"
      )
  end

  @spec ensure_hooks_folder_exists() :: any
  defp ensure_hooks_folder_exists do
    "/"
    |> GitPath.git_hooks_path_for()
    |> File.mkdir_p()
  end

  @spec clean_missing_hooks() :: any
  defp clean_missing_hooks do
    configured_git_hooks =
      Config.git_hooks()
      |> Enum.map(&Atom.to_string/1)

    "/git_hooks.db"
    |> GitPath.git_hooks_path_for()
    |> File.read()
    |> case do
      {:ok, file} ->
        file
        |> String.split(" ")
        |> Enum.each(fn installed_git_hook ->
          if installed_git_hook not in configured_git_hooks do
            git_hook_atom_as_kebab_string = Recase.to_kebab(installed_git_hook)

            Printer.warn(
              "Remove old git hook `#{git_hook_atom_as_kebab_string}` and restore backup"
            )

            git_hook_atom_as_kebab_string
            |> GitPath.git_hooks_path_for()
            |> File.rm()

            restore_backup(git_hook_atom_as_kebab_string)
          end
        end)

      _error ->
        :ok
    end
  end

  @spec restore_backup(String.t()) :: any
  defp restore_backup(git_hook_atom_as_kebab_string) do
    backup_path =
      GitPath.git_hooks_path_for("/#{git_hook_atom_as_kebab_string}.pre_git_hooks_backup")

    restore_path = GitPath.git_hooks_path_for(git_hook_atom_as_kebab_string)

    case File.rename(backup_path, restore_path) do
      :ok -> :ok
      {:error, reason} -> Printer.warn("Cannot restore backup: #{inspect(reason)}")
    end
  end
end

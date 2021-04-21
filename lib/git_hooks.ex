defmodule GitHooks do
  @moduledoc false

  alias Mix.Tasks.GitHooks.Install

  if Application.get_env(:git_hooks, :auto_install, true) do
    Install.run(["--quiet"])
  end

  alias Mix.Tasks.GitHooks.Run
  alias GitHooks.Tasks.File
  alias GitHooks.Tasks.Cmd
  alias GitHooks.Tasks.MFA
  alias GitHooks.Tasks.Mix, as: MixTask

  @opaque git_hook_args :: list(String.t())

  @spec new_task(String.t(), atom, git_hook_args()) :: :ok | no_return
  @spec new_task({:file, String.t(), Run.run_opts()}, atom, git_hook_args()) :: :ok | no_return
  @spec new_task({:cmd, String.t(), Run.run_opts()}, atom, git_hook_args()) :: :ok | no_return
  @spec new_task(mfa(), atom, git_hook_args()) :: :ok | no_return
  def new_task({:file, path}, git_hook_type, git_hook_args) do
    File.new({:file, path, []}, git_hook_type, git_hook_args)
  end

  def new_task({:file, _path, _opts} = file_config, git_hook_type, git_hook_args) do
    File.new(file_config, git_hook_type, git_hook_args)
  end

  def new_task({:cmd, command}, git_hook_type, git_hook_args) do
    Cmd.new({:cmd, command, []}, git_hook_type, git_hook_args)
  end

  def new_task({:cmd, _command, _opts} = cmd, git_hook_type, git_hook_args) do
    Cmd.new(cmd, git_hook_type, git_hook_args)
  end

  def new_task(command, git_hook_type, git_hook_args) when is_binary(command) do
    Cmd.new_from_string(command, git_hook_type, git_hook_args)
  end

  def new_task({:mix_task, _task} = mix_task_config, _git_hook_type, _git_hook_args) do
    MixTask.new(mix_task_config)
  end

  def new_task({_module, _function, _arity} = mfa, git_hook_type, git_hook_args) do
    MFA.new(mfa, git_hook_type, git_hook_args)
  end

  def new_task(task_config, git_hook_type, _git_hook_args) do
    raise """
    Invalid task #{inspect(task_config)} for hook #{inspect(git_hook_type)}", please check documentation.
    """
  end
end

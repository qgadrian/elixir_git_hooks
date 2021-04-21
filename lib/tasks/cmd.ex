defmodule GitHooks.Tasks.Cmd do
  defstruct [:original_command, :command, :args, :env, :git_hook_type, result: nil]

  @deprecated "Commands as string won't be supported and will be deleted in future versions"
  def new_from_string(command, git_hook_type, git_hook_args) when is_binary(command) do
    new({:cmd, command, []}, git_hook_type, git_hook_args)
  end

  def new({:cmd, original_command, opts}, git_hook_type, git_hook_args) when is_list(opts) do
    [base_command | args] = String.split(original_command, " ")

    command_args =
      if Keyword.get(opts, :include_hook_args, false) do
        Enum.concat(args, git_hook_args)
      else
        args
      end

    %__MODULE__{
      original_command: original_command,
      command: base_command,
      args: command_args,
      env: Keyword.get(opts, :env, []),
      git_hook_type: git_hook_type
    }
  end
end

defimpl GitHooks.Task, for: GitHooks.Tasks.Cmd do
  alias GitHooks.Config
  alias GitHooks.Tasks.Cmd
  alias GitHooks.Printer

  def run(%Cmd{command: command, args: args, env: env, git_hook_type: git_hook_type} = cmd, _opts) do
    result =
      System.cmd(
        command,
        args,
        into: Config.io_stream(git_hook_type),
        env: env
      )

    Map.put(cmd, :result, result)
  rescue
    error ->
      Map.put(cmd, :result, {"Execution failed: #{inspect(error)}", 1})
  end

  def success?(%Cmd{result: {_result, 0}}), do: true
  def success?(%Cmd{result: _}), do: false

  def print_result(%Cmd{original_command: original_command, result: {_result, 0}} = file) do
    Printer.success("`#{original_command}` was successful")

    file
  end

  def print_result(
        %Cmd{
          git_hook_type: git_hook_type,
          original_command: original_command,
          result: {_result, _code}
        } = file
      ) do
    # if !Config.verbose?(git_hook_type), do: IO.puts(result)

    Printer.error("`#{git_hook_type}`: `#{original_command}` execution failed")

    file
  end
end

defmodule GitHooks.Tasks.Cmd do
  @moduledoc """
  Represents a command that will be executed as a git hook task.

  A command should be configured as `{:cmd, command, opts}`, being `opts` an
  optional configuration.

  For example:

  ```elixir
  config :git_hooks,
    hooks: [
      pre_commit: [
        {:cmd, "ls -lisa", include_hook_args: true}
      ]
    ]
  ```
  """

  @typedoc """
  Represents a `command` to be executed.
  """
  @type t :: %__MODULE__{
          original_command: String.t(),
          command: String.t(),
          args: [any],
          env: [{String.t(), String.t()}],
          git_hook_type: atom,
          result: term
        }

  defstruct [:original_command, :command, :args, :env, :git_hook_type, result: nil]

  @doc """
  Creates a new `cmd` struct that will execute a command.

  This function expects a tuple or triple with `:cmd`, the command to execute
  and the opts.

  ### Options

  * `include_hook_args`: Whether the git options will be passed as argument when
  executing the file. You will need to check [which arguments are being sent by each git hook](https://git-scm.com/docs/githooks).
  * `env`: The environment variables that will be set in the execution context of the file.

  ### Examples

      iex> #{__MODULE__}.new({:cmd, "ls -l", env: [{"var", "test"}], include_hook_args: true}, :pre_commit, ["commit message"])
      %#{__MODULE__}{command: "ls", original_command: "ls -l", args: ["-l", "commit message"], env: [{"var", "test"}], git_hook_type: :pre_commit}

      iex> #{__MODULE__}.new({:cmd, "ls", include_hook_args: false}, :pre_commit, ["commit message"])
      %#{__MODULE__}{command: "ls", original_command: "ls", args: [], env: [], git_hook_type: :pre_commit}

  """
  @spec new(
          {:cmd, command :: String.t(), [any]},
          GitHooks.git_hook_type(),
          GitHooks.git_hook_args()
        ) ::
          __MODULE__.t()
  def new({:cmd, original_command, opts}, git_hook_type, git_hook_args) when is_list(opts) do
    env_vars = Keyword.get(opts, :env, [])
    include_hook_args = Keyword.get(opts, :include_hook_args, false)

    cmd_string =
      if include_hook_args do
        original_command <> " " <> Enum.join(git_hook_args, " ")
      else
        original_command
      end

    %__MODULE__{
      original_command: original_command,
      command: "sh",
      # ["-c", "full shell command"]
      args: ["-c", cmd_string],
      env: env_vars,
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

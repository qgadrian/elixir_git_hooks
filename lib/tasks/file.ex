defmodule GitHooks.Tasks.File do
  @moduledoc """
  Represents a file that will be executed as a git hook task.

  A file should be configured as `{:file, file_path, opts}`, being `opts` an
  optional configuration. The file should be readable and have execution
  permissions.

  See `#{__MODULE__}.new/1` for more information.

  For example:

  ```elixir
  config :git_hooks,
    hooks: [
      pre_commit: [
        {:file, "opt/scripts/checks", include_hook_args: true}
      ]
    ]
  ```
  """

  @typedoc """
  Represents a `file` to be executed.
  """
  @type t :: %__MODULE__{
          file_path: String.t(),
          args: [any],
          env: [{String.t(), String.t()}],
          git_hook_type: atom,
          result: term
        }

  defstruct [:file_path, :args, :env, :git_hook_type, result: nil]

  @doc """
  Creates a new `file` struct.

  This function expects a tuple or triple with `:file`, the file path and
  the opts.

  ### Options

  * `include_hook_args`: Whether the git options will be passed as argument when
  executing the file. You will need to check [which arguments are being sent by each git hook](https://git-scm.com/docs/githooks).
  * `env`: The environment variables that will be set in the execution context of the file.

  ### Examples

      iex> #{__MODULE__}.new({:file, :test, env: [{"var", "test"}], include_hook_args: true}, :pre_commit, ["commit message"])
      %#{__MODULE__}{file_path: :test, args: ["commit message"], env: [{"var", "test"}], git_hook_type: :pre_commit}

      iex> #{__MODULE__}.new({:file, :test, include_hook_args: false}, :pre_commit, ["commit message"])
      %#{__MODULE__}{file_path: :test, args: [], env: [], git_hook_type: :pre_commit}

  """
  @spec new(
          {:file, path :: String.t(), [any]},
          GitHooks.git_hook_type(),
          GitHooks.git_hook_args()
        ) ::
          __MODULE__.t()
  def new({:file, script_file, opts}, git_hook_type, git_hook_args) when is_list(opts) do
    args =
      if Keyword.get(opts, :include_hook_args, false) do
        git_hook_args
      else
        []
      end

    %__MODULE__{
      file_path: script_file,
      args: args,
      git_hook_type: git_hook_type,
      env: Keyword.get(opts, :env, [])
    }
  end
end

defimpl GitHooks.Task, for: GitHooks.Tasks.File do
  alias GitHooks.Config
  alias GitHooks.Tasks.File
  alias GitHooks.Printer

  def run(
        %File{file_path: script_file, env: env, args: args, git_hook_type: git_hook_type} = file,
        _opts
      ) do
    result =
      script_file
      |> Path.absname()
      |> System.cmd(
        args,
        into: Config.io_stream(git_hook_type),
        env: env
      )

    Map.put(file, :result, result)
  end

  def success?(%File{result: {_result, 0}}), do: true
  def success?(%File{result: _}), do: false

  def print_result(%File{file_path: file_path, result: {_result, 0}} = file) do
    Printer.success("`#{file_path}` was successful")

    file
  end

  def print_result(%File{file_path: file_path, result: {_result, _code}} = file) do
    Printer.error("`#{file_path}` execution failed")

    file
  end
end

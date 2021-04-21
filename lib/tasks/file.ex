defmodule GitHooks.Tasks.File do
  defstruct [:file_path, :args, :env, :git_hook_type, result: nil]

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

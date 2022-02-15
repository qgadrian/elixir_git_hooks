defmodule GitHooks.Tasks.Mix do
  @moduledoc """
  Represents a Mix task that will be executed as a git hook task.

  A mix task should be configured as `{:mix_task, task_name, task_args}`,
  being `task_args` an optional configuration. See `#{__MODULE__}.new/1` for
  more information.

  For example:

  ```elixir
  config :git_hooks,
    hooks: [
      pre_commit: [
        {:mix_task, :test},
        {:mix_task, :format, ["--dry-run"]}
      ]
    ]
  ```

  See `https://hexdocs.pm/mix/Mix.Task.html#run/2` for reference.
  """

  defstruct [:task, args: [], result: nil]

  @typedoc """
  Represents a Mix task.
  """
  @type t :: %__MODULE__{
          task: Mix.Task.task_name(),
          args: [any]
        }

  @doc """
  Creates a new Mix task struct.

  This function expects a tuple or triple with `:mix_task`, the task name and
  the task args.

  ### Examples

      iex> #{__MODULE__}.new({:mix_task, :test, ["--failed"]})
      %#{__MODULE__}{task: :test, args: ["--failed"]}

  """
  @spec new({:mix_task, Mix.Task.task_name(), [any]} | Mix.Task.task_name()) :: __MODULE__.t()
  def new({:mix_task, task, args}) do
    %__MODULE__{
      task: task,
      args: args
    }
  end
end

defimpl GitHooks.Task, for: GitHooks.Tasks.Mix do
  alias GitHooks.Tasks.Mix, as: MixTask
  alias GitHooks.Printer

  def run(%MixTask{task: :test, args: args} = mix_task, _opts) do
    args = ["test" | args] ++ ["--color"]

    {_, result} =
      System.cmd(
        "mix",
        args,
        into: IO.stream(:stdio, :line)
      )

    Map.put(mix_task, :result, result)
  end

  def run(%MixTask{task: task, args: args} = mix_task, _opts) do
    result = Mix.Task.run(task, args)

    Map.put(mix_task, :result, result)
  end

  # Mix tasks raise an error if they are valid, but determining if they are
  # success or not depends on the return of the task.
  @success_results [0, :ok, nil]

  def success?(%MixTask{result: result}) when result in @success_results, do: true
  def success?(%MixTask{result: _}), do: false

  def print_result(%MixTask{task: task, result: result} = mix_task)
      when result in @success_results do
    Printer.success("`#{task}` was successful")

    mix_task
  end

  def print_result(%MixTask{task: task, result: result} = mix_task) do
    Printer.error("mix task `#{task}` failed, return result: #{inspect(result)}")

    mix_task
  end
end

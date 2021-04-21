defmodule GitHooks.Tasks.Mix do
  defstruct [:task, args: [], result: nil]

  def new([{task, args}]) do
    %__MODULE__{
      task: task,
      args: args
    }
  end

  def new(task) do
    %__MODULE__{
      task: task
    }
  end
end

defimpl GitHooks.Task, for: GitHooks.Tasks.Mix do
  alias GitHooks.Tasks.Mix, as: MixTask
  alias GitHooks.Printer

  def run(%MixTask{task: task, args: args} = mix_task, _opts) do
    result = Mix.Task.run(task, args)

    Map.put(mix_task, :result, result)
  end

  def success?(%MixTask{result: :ok}), do: true
  def success?(%MixTask{result: _}), do: false

  def print_result(%MixTask{task: task, result: :ok} = mix_task) do
    Printer.success("`#{task}` was successful")

    mix_task
  end

  def print_result(%MixTask{task: task, result: _} = mix_task) do
    Printer.error("`#{task}` execution failed")

    mix_task
  end
end

defmodule GitHooks.Config.TasksConfig do
  @moduledoc false

  @doc """
  Given a git hook type, returns the list of tasks configured to be executed.
  """
  @spec tasks(atom) :: {atom, list(String.t())}
  def tasks(git_hook_type)

  def tasks(:all = git_hook_type) do
    tasks =
      :git_hooks
      |> Application.get_env(:hooks, [])
      |> Enum.reduce([], fn {_hook_type, hook_config}, acc ->
        hook_tasks = Keyword.get(hook_config, :tasks, [])
        acc ++ hook_tasks
      end)

    {git_hook_type, tasks}
  end

  def tasks(git_hook_type) do
    tasks =
      :git_hooks
      |> Application.get_env(:hooks, [])
      |> Keyword.get(git_hook_type, [])
      |> Keyword.get(:tasks, [])

    {git_hook_type, tasks}
  end
end

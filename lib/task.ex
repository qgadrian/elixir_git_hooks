defprotocol GitHooks.Task do
  @moduledoc false
  @fallback_to_any false

  @type opts :: [env: list(String.t())]

  @spec run(term, opts) :: term
  @doc """
  Runs the task.
  """
  def run(task, opts \\ [])

  @spec print_result(task :: term) :: task :: term
  @doc """
  Prints the execution result.
  """
  def print_result(task)

  @spec success?(task :: term) :: boolean
  @doc """
  Returns whether the task execution was successful or not.
  """
  def success?(task)
end

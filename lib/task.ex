defprotocol GitHooks.Task do
  @moduledoc false
  @fallback_to_any false

  alias GitHooks.Tasks.Cmd
  alias GitHooks.Tasks.File
  alias GitHooks.Tasks.MFA
  alias GitHooks.Tasks.Mix, as: MixTask

  @type opts :: [env: list(String.t())]

  @type t :: Cmd.t() | File.t() | MFA.t() | MixTask.t()

  @spec run(t(), opts) :: term
  @doc """
  Runs the task.
  """
  def run(task, opts \\ [])

  @spec print_result(t()) :: task :: term
  @doc """
  Prints the execution result.
  """
  def print_result(task)

  @spec success?(t()) :: boolean
  @doc """
  Returns whether the task execution was successful or not.
  """
  def success?(task)
end

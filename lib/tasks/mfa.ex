defmodule GitHooks.Tasks.MFA do
  @moduledoc """
  Represents a `{module, function, arity}` (a.k.a. `mfa`) that will be evaluated
  by the Kernel module.

  An `mfa` should be configured as `{module, function}`. The function of
  the module **will always receive the hook arguments as a list of argument** and the arity is
  expected to always be 1.

  See [Elixir documentation](https://hexdocs.pm/elixir/typespecs.html#types-and-their-syntax) for more information.

  For example:

  ```elixir
  config :git_hooks,
    hooks: [
      pre_commit: [
        {MyModule, :my_function}
      ]
    ]
  ```
  """

  @typedoc """
  Represents an `mfa` to be executed.
  """
  @type t :: %__MODULE__{
          module: atom,
          function: atom,
          args: [any],
          result: term
        }

  defstruct [:module, :function, args: [], result: nil]

  @doc """
  Creates a new `mfa` struct.

  ### Examples

      iex> #{__MODULE__}.new({MyModule, :my_function}, :pre_commit, ["commit message"])
      %#{__MODULE__}{module: MyModule, function: :my_function, args: ["commit message"]}

  """
  @spec new(mfa(), GitHooks.git_hook_type(), GitHooks.git_hook_args()) :: __MODULE__.t()
  def new({module, function}, _git_hook_type, git_hook_args) do
    %__MODULE__{
      module: module,
      function: function,
      args: git_hook_args
    }
  end
end

defimpl GitHooks.Task, for: GitHooks.Tasks.MFA do
  alias GitHooks.Tasks.MFA
  alias GitHooks.Printer

  # Kernel.apply will throw a error if something fails
  def run(
        %MFA{
          module: module,
          function: function,
          args: args
        } = mfa,
        _opts
      ) do
    result = Kernel.apply(module, function, [args])

    Map.put(mfa, :result, result)
  rescue
    error ->
      IO.warn(inspect(error))
      Map.put(mfa, :result, error)
  end

  def success?(%MFA{result: :ok}), do: true
  def success?(%MFA{result: _}), do: false

  def print_result(%MFA{module: module, function: function, result: :ok} = mix_task) do
    Printer.success("`#{module}.#{function}` was successful")

    mix_task
  end

  def print_result(%MFA{module: module, function: function, result: _} = mix_task) do
    Printer.error("`#{module}.#{function}` execution failed")

    mix_task
  end
end

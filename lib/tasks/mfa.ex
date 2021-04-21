defmodule GitHooks.Tasks.MFA do
  defstruct [:module, :function, args: [], result: nil]

  def new({module, function, arity}, git_hook_type, git_hook_args) do
    expected_arity = length(git_hook_args)

    if arity != expected_arity do
      raise """
      Invalid #{module}.#{function} arity for #{git_hook_type}, expected #{expected_arity} but got #{
        arity
      }. Check the Git hooks documentation to fix the expected parameters.
      """
    end

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
    result = Kernel.apply(module, function, args)

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

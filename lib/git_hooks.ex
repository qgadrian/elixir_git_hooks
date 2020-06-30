defmodule GitHooks do
  @moduledoc false

  alias Mix.Tasks.GitHooks.Install

  @doc """
  Receives the git hook name and the list of the hook arguments.

  To see how which arguments a git hook has, [check the git
  documentation](https://git-scm.com/docs/githooks).
  """
  @callback execute(atom, list) :: any

  if Application.get_env(:git_hooks, :auto_install, true) do
    Install.run(["--quiet"])
  end
end

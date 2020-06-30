defmodule GitHooks do
  @moduledoc false

  alias Mix.Tasks.GitHooks.Install

  if Application.get_env(:git_hooks, :auto_install, true) do
    Install.run(["--quiet"])
  end
end

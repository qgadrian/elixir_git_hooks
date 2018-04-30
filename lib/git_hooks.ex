defmodule GitHooks do
  @moduledoc """
  Module that provides the git hooks supported and installs automatically the configured hooks.
  """

  # credo:disable-for-next-line Credo.Check.Design.AliasUsage
  Mix.Tasks.GitHooks.Install.run(["--quiet"])
end

defmodule GitHooks.Git do
  @moduledoc false

  @spec git_version() :: Version.t()
  def git_version do
    {full_git_version, 0} = System.cmd("git", ["--version"])

    [version] = Regex.run(~r/\d\.\d+\.\d+/, full_git_version)

    Version.parse!(version)
  end
end

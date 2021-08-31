defmodule GitHooks.Config.VerboseConfig do
  @moduledoc false

  alias GitHooks.Config

  @doc """
  Returns the general verbose configuration.
  """
  @spec verbose?() :: boolean()
  def verbose? do
    Application.get_env(:git_hooks, :verbose, false)
  end

  @doc """
  Returns the verbose configuration for the git hooks, with a fallback for the
  general one.
  """
  @spec verbose?(atom) :: boolean()
  def verbose?(git_hook_type) do
    git_hook_type
    |> Config.get_git_hook_type_config()
    |> Keyword.get_lazy(:verbose, fn -> verbose?() end)
  end
end

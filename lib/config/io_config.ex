defmodule GitHooks.Config.IOConfig do
  @moduledoc false

  alias GitHooks.Config.VerboseConfig

  @doc """
  Returns the IO stream for the git hook.
  """
  @spec io_stream(atom) :: any()
  def io_stream(git_hook_type) do
    case VerboseConfig.verbose?(git_hook_type) do
      true -> IO.stream(:stdio, :line)
      _ -> ""
    end
  end
end

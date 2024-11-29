defmodule GitHooks.TestSupport.GitProjectCase do
  @moduledoc """
  This module provides a setup that creates a tmp git project 
  for the testing context
  """

  use ExUnit.CaseTemplate

  using do
    quote do
      setup do
        # Create a temporary directory
        tmp_dir = Path.join(System.tmp_dir!(), "git_hooks_test_#{:os.system_time(:millisecond)}")
        File.mkdir_p!(tmp_dir)

        # Initialize a git repository in the temporary directory
        System.cmd("git", ["init"], cd: tmp_dir)

        # Set the :project_path in Application environment
        Application.put_env(:git_hooks, :project_path, tmp_dir)

        # Return the context with the tmp_dir
        {:ok, tmp_dir: tmp_dir}
      end
    end
  end
end

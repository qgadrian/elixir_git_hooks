defmodule GitHooks.TestSupport.GitProjectCase do
  @moduledoc """
  This module provides a setup that creates a tmp git project 
  for the testing context.
  """

  use ExUnit.CaseTemplate

  using do
    quote do
      setup do
        tmp_dir = Path.join(System.tmp_dir!(), "git_hooks_test_#{:os.system_time(:millisecond)}")
        File.mkdir_p!(tmp_dir)

        System.cmd("git", ["init"], cd: tmp_dir)

        Application.put_env(:git_hooks, :project_path, tmp_dir)

        on_exit(fn ->
          File.rm_rf(tmp_dir)
        end)

        {:ok, tmp_dir: tmp_dir}
      end
    end
  end
end

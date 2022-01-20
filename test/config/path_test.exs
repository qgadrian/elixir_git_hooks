defmodule GitHooks.PathTest do
  @moduledoc false

  use ExUnit.Case, async: false
  use GitHooks.TestSupport.ConfigCase

  alias GitHooks.Git

  describe "Given a git hook type" do
    @tag :tmp_dir
    test "when inside a normal git repo at toplevel", %{tmp_dir: tmp_dir} do
      copy_fake_git_dir(tmp_dir)
      assert Git.path_from_git(tmp_dir) == {:ok, Path.join(tmp_dir, ".git")}
    end

    @tag :tmp_dir
    test "when inside a normal git repo with git-hooks cloned in deps folder", %{tmp_dir: tmp_dir} do
      dep_dir = Path.join([tmp_dir, "deps", "git-hooks"])
      File.mkdir_p!(dep_dir)
      copy_fake_git_dir(tmp_dir)
      copy_fake_git_dir(dep_dir)
      assert Git.path_from_git(tmp_dir) == {:ok, Path.join(tmp_dir, ".git")}
    end

    @tag :tmp_dir
    test "when inside a git repo where the elixir project is not the root", %{tmp_dir: tmp_dir} do
      all_levels = increasing_levels(tmp_dir)

      for {top_name, deep_dir} <- all_levels do
        assert Git.path_from_git(deep_dir) == {:ok, Path.join([tmp_dir, top_name, ".git"])}
      end
    end

    @tag :tmp_dir
    test "when git is not installed", %{tmp_dir: tmp_dir} do
      assert Git.path_from_git(tmp_dir, "fakegit") == {:error, :no_system_git}
      path = Path.join([Mix.Project.deps_path(), "..", ".git"])
      message = "Error resolving git submodule path '#{path}'"

      assert_raise RuntimeError, fn ->
        Git.use_legacy_configuration()
      end
    end
  end

  # generates a list of directories, each one one level deeper than the previous one
  defp increasing_levels(path) do
    for i <- ?a..?c, into: [] do
      top_basename = to_string(i)
      top_directory = Path.join([path, top_basename])
      paths = Enum.map(?a..i, fn n -> to_string([n]) end)
      final_dir = Path.join([top_directory] ++ paths)
      File.mkdir_p!(final_dir)
      copy_fake_git_dir(top_directory)
      {top_basename, final_dir}
    end
  end

  defp copy_fake_git_dir(path) do
    git_dir = Path.join([path, ".git"])
    File.cp_r!(Path.join(File.cwd!(), "test/fixtures/fake_git_dir"), git_dir)
  end
end

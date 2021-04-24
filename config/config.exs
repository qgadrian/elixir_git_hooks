use Mix.Config

config :git_hooks,
  auto_install: false,
  hooks: [
    # prepare_commit_msg: [
    # verbose: true,
    # tasks: [
    # {MyApp.GitHooks.PrepareCommitMsg, :execute, 4}
    # ]
    # ],
    commit_msg: [
      verbose: true,
      tasks: [
        {:file, "./priv/test_script", include_hook_args: true},
        {:cmd, "elixir ./priv/test_task.ex", include_hook_args: true}
      ]
    ],
    pre_commit: [
      verbose: true,
      tasks: [
        {:mix_task, :format, ["--check-formatted", "--dry-run"]},
        {:mix_task, :credo}
      ]
    ],
    pre_push: [
      verbose: true,
      tasks: [
        {:mix_task, :dialyzer},
        {:mix_task, :test, ["--color"]},
        {:mix_task, :coveralls}
      ]
    ]
  ]

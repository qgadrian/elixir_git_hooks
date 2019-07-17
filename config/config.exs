use Mix.Config

config :git_hooks,
  hooks: [
    commit_msg: [
      verbose: true,
      tasks: [
        {:file, "./priv/test_script", include_hook_args?: true},
        {:cmd, "elixir ./priv/test_task.ex", include_hook_args?: true}
      ]
    ],
    pre_commit: [
      verbose: true,
      tasks: [
        "mix format --check-formatted --dry-run",
        "mix credo"
      ]
    ],
    pre_push: [
      verbose: true,
      tasks: [
        "mix dialyzer",
        "mix coveralls"
      ]
    ]
  ]

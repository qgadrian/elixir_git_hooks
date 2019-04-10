use Mix.Config

config :git_hooks,
  hooks: [
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

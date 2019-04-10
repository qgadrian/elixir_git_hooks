use Mix.Config

config :git_hooks,
  hooks: [
    pre_commit: [
      verbose: true,
      mix_tasks: [
        "format --check-formatted --dry-run",
        "credo"
      ]
    ],
    pre_push: [
      verbose: true,
      mix_tasks: [
        "dialyzer",
        "coveralls"
      ]
    ]
  ]

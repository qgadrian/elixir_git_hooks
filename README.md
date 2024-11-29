[![Coverage Status](https://coveralls.io/repos/github/qgadrian/elixir_git_hooks/badge.svg?branch=master)](https://coveralls.io/github/qgadrian/elixir_git_hooks?branch=master)
[![Hex version](https://img.shields.io/hexpm/v/sippet.svg "Hex version")](https://hex.pm/packages/git_hooks)
[![Hex Docs](https://img.shields.io/badge/hex-docs-9768d1.svg)](https://hexdocs.pm/git_hooks)
[![Build Status](https://travis-ci.org/qgadrian/elixir_git_hooks.svg?branch=master)](https://travis-ci.org/qgadrian/elixir_git_hooks.svg?branch=master)
[![Inline docs](http://inch-ci.org/github/qgadrian/elixir_git_hooks.svg)](http://inch-ci.org/github/qgadrian/elixir_git_hooks)

# GitHooks 🪝

<!--toc:start-->

- [Project description](#project-description)
  - [Why use git hooks?](#why-use-git-hooks)
- [Installation](#installation)
  - [Backup current hooks](#backup-current-hooks)
  - [Automatic installation](#automatic-installation)
  - [Manual installation](#manual-installation)
- [Configuration](#configuration)
  - [Auto install](#auto-install)
  - [Hook configuration](#hook-configuration)
  - [Git submodules](#git-submodules)
  - [Custom project path](#custom-project-path)
  - [Custom mix path](#custom-mix-path)
    - [Troubleshooting in docker containers](#troubleshooting-in-docker-containers)
  - [Example config](#example-config)
  - [Task types](#task-types)
    - [Mix task](#mix-task)
    - [Command](#command)
    - [Executable file](#executable-file)
    - [Elixir module](#elixir-module)
- [Removing a hook](#removing-a-hook)
- [Recipes](#recipes)
  - [Running pre-commit hook only for staged files](#running-pre-commit-hook-only-for-staged-files)
- [Execution](#execution)
  - [Automatic execution](#automatic-execution)
  - [Manual execution](#manual-execution)
- [Copyright and License](#copyright-and-license)
<!--toc:end-->

## Project description

Configure [git hooks](https://git-scm.com/docs/githooks) in your Elixir projects.

#### Why use git hooks?

- Enforces code quality: Automatically run tests, formatters, linters... before every
  commit or push to ensure code consistency.
- Prevent errors earlier: Catch issues with `pre-commit` or `pre-push`, reducing the
  chance of broken builds and saving minutes and time in the CI or code review.
- Improve workflows: Automate repetitive tasks, unify command execution, ensure
  consistent standards across the team...

Main features:

- **Simplicity**: Automatic or manually install the configured git hook actions.
- **Flexibility**: You choose what to use to define the git hooks actions:
  - Bash commands
  - Executable files
  - Elixir modules
- **No limits**: Any git hook is and will be supported out of the box,
  you can [check here the git hooks list](https://git-scm.com/docs/githooks)
  available.

## Installation

Add to dependencies:

```elixir
def deps do
  [
    {:git_hooks, "~> 0.8.0", only: [:dev], runtime: false}
  ]
end
```

Then install and compile the dependencies:

```bash
mix deps.get && mix deps.compile
```

### Backup current hooks

This library will backup automatically your current git hooks before
overwriting them.

The backup files will have the file extension `.pre_git_hooks_backup`

### Automatic installation

This library will install automatically the configured git hooks in your
`config.exs` file.

See [configuration](#disable-auto-install) to disable the automatic install.

### Manual installation

If you prefer **not to enforce git hooks in a project**, you can still define
recommended hooks and allow team members to install them manually by running:

```bash
mix git_hooks.install
```

## Configuration

### Auto install

To disable the automatic install of the git hooks set the configuration key `auto_install` to
`false`.

### Hook configuration

One or more git hooks can be configured, those hooks will be the ones
[installed](#installation) in your git project.

Currently there are supported two configuration options:

- **tasks**: A list of the commands that will be executed when running a git hook. [See types of tasks](#type-of-tasks) for more info.
- **verbose**: If true, the output of the mix tasks will be visible. This can be configured globally or per git hook.
- **branches**: Allow or forbid the hook configuration to run (or not) in certain branches using `whitelist` or `blacklist` configuration (see example below). You can use regular expressions to match a branch name.

### Git submodules

This library supports git submodules, just add your `git_hooks` configuration to
any of the submodules projects.

Setting a custom _git hooks_ config path is also supported:

```
git config core.hooksPath .myCustomGithooks/
```

### Custom project path

This library assumes a simple Elixir project architecture. This is, an Elixir
project in the root of a git repository.

If you have a different project architecture, you can specify the absolute path
of your project using the `project_path` configuration:

```elixir
{project_path, 0} = System.cmd("pwd", [])
project_path = String.replace(project_path, ~r/\n/, "/")

config :git_hooks,
  hooks: [
    pre_commit: [
      tasks: [
        {:cmd, "mix format --check-formatted"}
      ]
    ]
  ],
  project_path: project_path
```

### Custom mix path

This library expects `elixir` to be installed in your system and the `mix` binary to be available. If you want to provide a specific path to run the `mix` executable, it can be done using the `mix_path` configuration.

The following example would run the hooks on a docker container:

```elixir
config :git_hooks,
  auto_install: false,
  mix_path: "docker-compose exec mix",
```

##### Troubleshooting in docker containers

The `mix_path` configuration can be used to run mix hooks on a Docker container.
If you have a TTY error running mix in a Docker container use `docker exec --tty $(docker-compose ps -q web) mix` as the `mix_path`. See this [issue](https://github.com/qgadrian/elixir_git_hooks/issues/82) as reference.

### Example config

In `config/config.exs`

```elixir
use Mix.Config

# somewhere in your config file
if Mix.env() == :dev do
  config :git_hooks,
    auto_install: true,
    verbose: true,
    branches: [
      whitelist: ["feature-.*"],
      blacklist: ["master"]
    ],
    hooks: [
      pre_commit: [
        tasks: [
          {:cmd, "mix format --check-formatted"}
        ]
      ],
      pre_push: [
        verbose: false,
        tasks: [
          {:cmd, "mix dialyzer"},
          {:cmd, "mix test --color"},
          {:cmd, "echo 'success!'"}
        ]
      ]
    ]
end
```

### Task types

> For more information, check the [module
> documentation](https://hexdocs.pm/git_hooks) for each of the different
> supported tasks.

#### Mix task

This is the preferred option to run mix tasks, as it will provide the best
execution feedback.

Just add in your config the mix tasks you want to run. You can also set the args
to be used by the mix task:

```elixir
config :git_hooks,
  verbose: true,
  hooks: [
    commit_msg: [
      tasks: [
        {:mix_task, :test},
        {:mix_task, :format, ["--dry-run"]}
      ]
    ]
  ]
```

By default this library expects by default the following return values from mix tasks:

```elixir
0
:ok
nil
```

If you want to support additional success return values from your mix tasks, you
can add them by adding the following configuration:

```elixir
config :git_hooks,
  extra_success_returns: [
    {:noop, []},
    {:ok, []}
  ]
```

#### Command

To run a simple command you can either declare a string or a tuple with the
command you want to run. For example, having `"mix test"` and `{:cmd, "mix
test"}` in the hook `tasks` will be equivalent.

> If you want to forward the git hook arguments, add the option
> `include_hook_args: true`.

```elixir
config :git_hooks,
  verbose: true,
  hooks: [
    commit_msg: [
      tasks: [
        {:cmd, "echo 'test'"},
        {:cmd, "elixir ./priv/test_task.ex", include_hook_args: true},
      ]
    ]
  ]
```

#### Executable file

The following configuration uses a script file to be run with a git hook. If you
want to forward the git hook arguments, add the option `include_hook_args:
true`.

```elixir
config :git_hooks,
  verbose: true,
  hooks: [
    commit_msg: [
      tasks: [
        {:file, "./priv/test_script"},
        {:file, "./priv/test_script_with_args", include_hook_args: true},
      ]
    ]
  ]
```

The script file executed will receive the arguments from git, so you can use
them as you please.

#### Elixir module

It is also possible to use Elixir modules to execute actions for a given git
hook.

Just add in your config the
[MFA](https://hexdocs.pm/elixir/typespecs.html#built-in-types) (`{module,
function, arity}`) definition:

```elixir
config :git_hooks,
  verbose: true,
  hooks: [
    commit_msg: [
      tasks: [
        {MyModule, :execute, 2}
      ]
    ]
  ]
```

To check how many args you function should expect [check the git
documentation](https://git-scm.com/docs/githooks) to know which parameters are
being sent on each hook.

## Removing a hook

When a git hook configuration is removed, the installed hook will automatically
delete it.

Any backup done at the moment will still be kept.

## Recipes

List of recipes that can be useful to setup your git hooks.

### Running pre-commit hook only for staged files

```elixir
{:mix_task, "credo", ["$(git diff --name-only --cached)", " --strict"]}
```

## Execution

### Automatic execution

The configured mix tasks will run automatically for each [git
hook](https://git-scm.com/docs/githooks#_hooks).

### Manual execution

You can also run manually any configured git hook as well.

The following example will run the pre_commit configuration:

```bash
mix git_hooks.run pre_commit
```

It is also possible to run all the configured hooks:

```bash
mix git_hooks.run all
```

## Copyright and License

Copyright © 2022-present Adrián Quintás

Source code is released under [the MIT license](./LICENSE).

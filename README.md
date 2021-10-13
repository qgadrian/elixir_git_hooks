[![Coverage Status](https://coveralls.io/repos/github/qgadrian/elixir_git_hooks/badge.svg?branch=master)](https://coveralls.io/github/qgadrian/elixir_git_hooks?branch=master)
[![Hex version](https://img.shields.io/hexpm/v/sippet.svg "Hex version")](https://hex.pm/packages/git_hooks)
[![Hex Docs](https://img.shields.io/badge/hex-docs-9768d1.svg)](https://hexdocs.pm/git_hooks)
[![Build Status](https://travis-ci.org/qgadrian/elixir_git_hooks.svg?branch=master)](https://travis-ci.org/qgadrian/elixir_git_hooks.svg?branch=master)
[![Inline docs](http://inch-ci.org/github/qgadrian/elixir_git_hooks.svg)](http://inch-ci.org/github/qgadrian/elixir_git_hooks)

# GitHooks

Configure [git hooks](https://git-scm.com/docs/githooks) in your Elixir
projects.

Main features are:

* **Simplicity**: Automatic or manually install the configured git hook actions.
* **Flexibility**: You choose what to use to define the git hooks actions:
  * Bash commands
  * Executable files
  * Elixir modules
* **No limits**: Any git hook is and will be supported out of the box,
 you can [check here the git hooks list](https://git-scm.com/docs/githooks)
 available.

## Table of Contents


<!-- vim-markdown-toc GFM -->

* [Installation](#installation)
  * [Backup current hooks](#backup-current-hooks)
  * [Automatic installation](#automatic-installation)
  * [Manual installation](#manual-installation)
* [Configuration](#configuration)
  * [Mix path](#mix-path)
  * [Git path](#git-path)
    * [Troubleshooting in docker containers](#troubleshooting-in-docker-containers)
  * [Auto install](#auto-install)
  * [Hook configuration](#hook-configuration)
  * [Example config](#example-config)
  * [Type of tasks](#type-of-tasks)
    * [Mix task](#mix-task)
    * [Command](#command)
    * [Executable file](#executable-file)
    * [Elixir module](#elixir-module)
* [Removing a hook](#removing-a-hook)
* [Execution](#execution)
  * [Automatic execution](#automatic-execution)
  * [Manual execution](#manual-execution)
* [Copyright and License](#copyright-and-license)

<!-- vim-markdown-toc -->

## Installation

Add to dependencies:

```elixir
def deps do
  [
    {:git_hooks, "~> 0.6.4", only: [:dev], runtime: false}
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

The backup files will have the file extension `.pre_git_hooks_backup`.

### Automatic installation

This library will install automatically the configured git hooks in your
`config.exs` file.

See [configuration](#disable-auto-install) to disable the automatic install.

### Manual installation

You can manually install the configured git hooks at any time by running:

```bash
mix git_hooks.install
```

## Configuration

### Mix path

This library expects `elixir` to be installed in your system and the `mix` binary to be available. If you want to provide an specific path to run the `mix` executable, it can be done using the `mix_path` configuration.

The following example would run the hooks on a docker container:

```elixir
config :git_hooks,
  auto_install: false,
  mix_path: "docker-compose exec mix",
```

### Git path

This library expects `git` to be installed in the `.git` directory relative to your project root, or when using git submodules, the root of the superproject. If you want to provide a specific path to a custom git directory, it can be done using the `git_path` configuration.

The follow example would run the hooks within a git submodule:

```elixir
config :git_hooks,
  git_path: "../.git/modules/submodule-repo"
```

#### Troubleshooting in docker containers

The `mix_path` configuration can be use to run mix hooks on a Docker container.
If you have a TTY error running mix in a Docker container use `docker exec --tty $(docker-compose ps -q web) mix` as the `mix_path`. See this [issue](https://github.com/qgadrian/elixir_git_hooks/issues/82) as reference.

### Auto install

To disable the automatic install of the git hooks set the configuration key `auto_install` to
`false`.

### Hook configuration

One or more git hooks can be configured, those hooks will be the ones
[installed](#installation) in your git project.

Currently there are supported two configuration options:

  * **tasks**: A list of the commands that will be executed when running a git hook. [See types of tasks](#type-of-tasks) for more info.
  * **verbose**: If true, the output of the mix tasks will be visible. This can be configured globally or per git hook.
  * **branches**: Allow or forbid the hook configuration to run (or not) in certain branches using `whitelist` or `blacklist` configuration (see example below).You can use regular expressions to match a branch name.

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

### Type of tasks

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

Copyright © 2021 Adrián Quintás

Source code is released under [the MIT license](./LICENSE).

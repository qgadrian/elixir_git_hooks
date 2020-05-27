[![Coverage Status](https://coveralls.io/repos/github/qgadrian/elixir_git_hooks/badge.svg?branch=master)](https://coveralls.io/github/qgadrian/elixir_git_hooks?branch=master)
[![Hex version](https://img.shields.io/hexpm/v/sippet.svg "Hex version")](https://hex.pm/packages/git_hooks)
[![Hex Docs](https://img.shields.io/badge/hex-docs-9768d1.svg)](https://hexdocs.pm/git_hooks)
[![Build Status](https://travis-ci.org/qgadrian/elixir_git_hooks.svg?branch=master)](https://travis-ci.org/qgadrian/elixir_git_hooks.svg?branch=master)
[![Inline docs](http://inch-ci.org/github/qgadrian/elixir_git_hooks.svg)](http://inch-ci.org/github/qgadrian/elixir_git_hooks)

# GitHooks

Installs [git hooks](https://git-scm.com/docs/githooks) that will run in your
Elixir project.

Any git hook type is supported, [check here the hooks
list](https://git-scm.com/docs/githooks).

## Table of Contents

<!-- vim-markdown-toc Marked -->

* [Installation](#installation)
  * [Backup current hooks](#backup-current-hooks)
  * [Automatic installation](#automatic-installation)
  * [Manual installation](#manual-installation)
* [Configuration](#configuration)
  * [Disable auto install](#disable-auto-install)
  * [Example config](#example-config)
  * [Type of tasks](#type-of-tasks)
    * [Command](#command)
    * [Executable file](#executable-file)
* [Removing a hook](#removing-a-hook)
* [Execution](#execution)
  * [Automatic execution](#automatic-execution)
  * [Manual execution](#manual-execution)

<!-- vim-markdown-toc -->

## Installation

Add to dependencies:

```elixir
def deps do
  [{:git_hooks, "~> 0.4.2", only: [:test, :dev], runtime: false}]
end
```

Then install and compile the dependencies:

```bash
mix deps.get && mix deps.compile
```

### Backup current hooks

This project will backup automatically your the hook files that are going to be
overwrite.

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

One or more git hooks can be configured, those hooks will be the ones
[installed](#installation) in your git project.

Currently there are supported two configuration options:

  * **tasks**: A list of the commands that will be executed when running a git hook. [See types of tasks](#type-of-tasks) for more info.
  * **verbose**: If true, the output of the mix tasks will be visible. This can be configured globally or per git hook.

### Disable auto install

To disable the automatic install of the git hooks set the configuration key `auto_install` to
`false`.

### Example config

In `config/config.exs`

```elixir
if Mix.env() != :prod do
  config :git_hooks,
    auto_install: true,
    verbose: true,
    hooks: [
      pre_commit: [
        tasks: [
          "mix format"
        ]
      ],
      pre_push: [
        verbose: false,
        tasks: [
          "mix dialyzer",
          "mix test",
          "echo 'success!'"
        ]
      ]
    ]
end
```

### Type of tasks

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

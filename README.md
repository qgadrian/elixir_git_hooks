[![Coverage Status](https://coveralls.io/repos/github/qgadrian/elixir_git_hooks/badge.svg?branch=master)](https://coveralls.io/github/qgadrian/elixir_git_hooks?branch=master)
[![Hex version](https://img.shields.io/hexpm/v/sippet.svg "Hex version")](https://hex.pm/packages/git_hooks)
[![Hex Docs](https://img.shields.io/badge/hex-docs-9768d1.svg)](https://hexdocs.pm/git_hooks)
[![Build Status](https://travis-ci.org/qgadrian/metadata_plugs.svg?branch=master)](https://travis-ci.org/qgadrian/elixir_git_hooks.svg?branch=master)
[![Deps Status](https://beta.hexfaktor.org/badge/all/github/qgadrian/elixir_git_hooks.svg)](https://beta.hexfaktor.org/github/qgadrian/elixir_git_hooks)
[![Inline docs](http://inch-ci.org/github/qgadrian/elixir_git_hooks.svg)](http://inch-ci.org/github/qgadrian/elixir_git_hooks)

# GitHooks

Installs [git hooks](https://git-scm.com/docs/githooks) that will run in your Elixir project.

Any git hook type is supported, [check here the hooks list](https://git-scm.com/docs/githooks).

## Table of Contents

- [Installation](#installation)
  - [Backup](#backup-current-hooks)
  - [Automatic](#automatic-installation)
  - [Manual](#manual-installation)
- [Configuration](#configuration)
- [Execution](#execution)
  - [Supported hooks](#supported-hooks)
  - [Automatic](#automatic-execution)
  - [Manual](#manual-execution)

## Installation

Add to dependencies:

```elixir
def deps do
  [{:git_hooks, "~> 0.2.0"}]
end
```

Then install and compile the dependencies:

```bash
mix deps.get && mix deps.compile
```

### Backup current hooks

This project will backup automatically your the hook files that are going to be overwrite.

The backup files will have the file extension `.pre_git_hooks_backup`.

### Automatic installation

This library will install automatically the configured git hooks in your `config.exs` file.

### Manual installation

You can manually install the configured git hooks at any time by running:

```bash
mix git_hooks.install
```

## Configuration

One or more git hooks can be configured, those hooks will be the ones [installed](#installation) in your git project.

Currently there are supported two configuration options:
  * **mix_tasks**: A list of the mix tasks that will run for the git hook
  * **verbose**: If true, the output of the mix tasks will be visible. This can be configured globally or per git hook.

```elixir
config :git_hooks,
  verbose: true,
  hooks: [
    pre_commit: [
      mix_tasks: [
        "format"
      ]
    ],
    pre_push: [
      verbose: false,
      mix_tasks: [
        "dialyzer",
        "test"
      ]
    ]
  ]
```

## Execution

### Automatic execution

The configured mix tasks will run automatically for each [git hook](https://git-scm.com/docs/githooks#_hooks).

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

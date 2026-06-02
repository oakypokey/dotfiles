# Dotfiles managed with chezmoi

This repository is the source directory for [`chezmoi`](https://www.chezmoi.io/), which manages my dotfiles and applies them into `$HOME`.

## How this repo uses chezmoi

`chezmoi` keeps a separate source state and maps files in this repo to their final locations in my home directory.

- `dot_zshrc` becomes `~/.zshrc`
- `dot_gitconfig.tmpl` becomes `~/.gitconfig`
- `dot_Brewfile` becomes `~/.Brewfile`
- `dot_config/opencode/opencode.jsonc.tmpl` becomes `~/.config/opencode/opencode.jsonc`
- `.chezmoi.toml.tmpl` is the templated `chezmoi` config used to populate data values

The `dot_` prefix is a `chezmoi` naming convention for files that should be written with a leading `.` in the target path.

Template files ending in `.tmpl` are rendered by `chezmoi` before being written. In this repo:

- `.chezmoi.toml.tmpl` prompts once for `name` and `email`
- `dot_gitconfig.tmpl` uses those values to fill in the Git user configuration
- `dot_config/opencode/opencode.jsonc.tmpl` uses a prompted `opencode_host` value for local provider URLs

That means the committed files can stay reusable while machine- or user-specific values are injected at apply time.

## Common commands

Preview changes:

```sh
chezmoi diff
```

Apply the dotfiles:

```sh
chezmoi apply
```

Edit a managed file through `chezmoi`:

```sh
chezmoi edit ~/.zshrc
```

Add an existing file from `$HOME` into the source state:

```sh
chezmoi add ~/.somefile
```

## Homebrew workflow

Homebrew packages are tracked with a managed `~/.Brewfile`.

- The `brew()` shell wrapper in `dot_zshrc` runs `brew bundle dump` after `install`, `uninstall`, `tap`, and related package-changing commands
- The generated bundle is written back into this `chezmoi` repo by resolving the source path for `~/.Brewfile`
- `chezmoi apply` runs `brew bundle --file="$HOME/.Brewfile"` to install everything listed in that Brewfile

## Repository layout

- `dot_zshrc`: shell configuration
- `dot_gitconfig.tmpl`: templated Git config
- `dot_Brewfile`: Homebrew bundle definition
- `dot_config/opencode/opencode.jsonc.tmpl`: templated OpenCode config
- `iterm.config.json`: iTerm configuration tracked alongside the dotfiles

## Bootstrapping

On a new machine, initialize `chezmoi` with this repo and apply it:

```sh
chezmoi init --apply <repo>
```

During the first apply, `chezmoi` will prompt for the values defined in `.chezmoi.toml.tmpl`, including the OpenCode host/IP used by the local provider base URLs.

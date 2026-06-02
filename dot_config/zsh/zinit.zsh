ZINIT_HOME="${XDG_DATA_HOME:-${HOME}/.local/share}/zinit/zinit.git"

if [[ ! -d "$ZINIT_HOME" ]]; then
  mkdir -p "$(dirname "$ZINIT_HOME")"
  git clone https://github.com/zdharma-continuum/zinit.git "$ZINIT_HOME"
fi

source "${ZINIT_HOME}/zinit.zsh"

zinit light zsh-users/zsh-syntax-highlighting
zinit light zsh-users/zsh-completions
zinit light zsh-users/zsh-autosuggestions
zinit light Aloxaf/fzf-tab

zinit snippet OMZP::git
zinit snippet OMZP::sudo
zinit snippet OMZP::aws
zinit snippet OMZP::command-not-found
zinit snippet "https://github.com/MichaelAquilina/zsh-auto-notify/blob/27c07dddb42f05b199319a9b66473c8de7935856/auto-notify.plugin.zsh"
zinit snippet "https://github.com/MichaelAquilina/zsh-you-should-use/blob/fc0be82b42b1cb205e67dbb4520cb77e248f710d/you-should-use.plugin.zsh"

autoload -U compinit && compinit

zinit cdreplay -q

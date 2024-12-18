if [[ -f "/opt/homebrew/bin/brew" ]] then
  # If you're using macOS, you'll want this enabled
  eval "$(/opt/homebrew/bin/brew shellenv)"
fi

# Set the directory we want to store zinit and plugins
ZINIT_HOME="${XDG_DATA_HOME:-${HOME}/.local/share}/zinit/zinit.git"

# Download Zinit, if it's not there yet
if [ ! -d "$ZINIT_HOME" ]; then
   mkdir -p "$(dirname $ZINIT_HOME)"
   git clone https://github.com/zdharma-continuum/zinit.git "$ZINIT_HOME"
fi

# Source/Load zinit
source "${ZINIT_HOME}/zinit.zsh"

# Add in zsh plugins
zinit light zsh-users/zsh-syntax-highlighting # syntax highlighting
zinit light zsh-users/zsh-completions # completions using tab
zinit light zsh-users/zsh-autosuggestions # auto suggestions
zinit light Aloxaf/fzf-tab # use fzf with other things
zinit light sudosubin/zsh-poetry # poetry completions

# Add snippets
zinit snippet OMZP::git
zinit snippet OMZP::sudo
zinit snippet OMZP::aws
zinit snippet OMZP::command-not-found
zinit snippet "https://github.com/MichaelAquilina/zsh-auto-notify/blob/27c07dddb42f05b199319a9b66473c8de7935856/auto-notify.plugin.zsh"
zinit snippet "https://github.com/MichaelAquilina/zsh-you-should-use/blob/fc0be82b42b1cb205e67dbb4520cb77e248f710d/you-should-use.plugin.zsh"


# Load autocompletions
autoload -U compinit && compinit

zinit cdreplay -q # replay all cached completions (recommended by docs)

# Oh-my-posh init
if [ "$TERM_PROGRAM" != "Apple_Terminal" ]; then
  eval "$(oh-my-posh init zsh --config ~/dotfiles/ohmyposh/robbyrussel.omp.json)"
fi

# Aliases
alias ls='ls --color'
alias python=python3
alias cde='code $(fzfg -m --preview="bat --color=always {}")'

# Utilities
## Checks to see if python venv exists otherwise creates new one
sauce () {
    if [ ! -d ".venv" ]; then
        echo "Creating a new environment...";
        python3 -m venv ./.venv;
    fi

    source ./.venv/bin/activate;
}

# Keybindings
bindkey '^f' autosuggest-accept # accept suggesstions
bindkey '^[[A' history-search-backward # search backwards using history up key
bindkey '^[[B' history-search-forward # search forward using history down key

# History
HISTSIZE=5000
HISTFILE=~/.zsh_history
SAVEHIST=$HISTSIZE
HISTDUP=erase
setopt appendhistory # adds history to history file
setopt sharehistory # share history across zsh sessions
setopt hist_ignore_space # does not add line to history if it starts with space
setopt hist_ignore_all_dups # stop dupe commands being saved to history
setopt hist_save_no_dups # stop dupe commands being saved to history
setopt hist_ignore_dups # stop dupe commands being saved to history
setopt hist_find_no_dups # don't see dups in history when searching

# Completion styling
zstyle ':completion:*' matcher-list 'm:{a-z}={A-Za-z}' # match even if case doesn't match
zstyle ':completion:*' list-colors "${(s.:.)LS_COLORS}" # color autocompletions
zstyle ':completion:*' menu no # disable default menu for fzf
zstyle ':fzf-tab:complete:cd:*' fzf-preview 'tree -L 2 -C $realpath' # add fzf preview for directories
zstyle ':fzf-tab:complete:__zoxide_z:*' fzf-preview 'tree -L 2 -C $realpath'

# Shell integrations
eval "$(fzf --zsh)" # fzf integration -- make sure installed via pkg manager like brew
eval "$(zoxide init --cmd cd zsh)" # add zoxide (better cd) - install via brew
eval "$(pyenv virtualenv-init -)" # add pyenv management

export FZF_DEFAULT_COMMAND="fd --hidden --strip-cwd-prefix --exclude .git"
export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
export FZF_ALT_C_COMMAND="fd --type=d --hidden --strip-cwd-prefix --exclude .git"

export FZF_CTRL_T_OPTS="--preview 'bat -n --color=always --line-range :500 {}'"

_fzf_compgen_path() {
  fd --hidden --exclude .git . "$1"
}

_fzf_compgen_dir(){
  fd --type=d --hidden --exclude .git . "$1"
}

_fzf_comprun() {
  local command=$1
  shift

  case "$command" in
    cd)           fzf --preview "tree -L 2 -C {}"        "$@" ;;
    export|unset) fzf --preview "eval 'echo \${}'" "$@" ;;
    ssh)          fzf --preview 'dig {}'            "$@" ;;
    *)            fzf --preview "bat -n --color=always --line-range :500 {}" "$@" ;; 
  esac
}

source ~/Bin/scripts/fzf-git.sh/fzf-git.sh

# Created by `pipx` on 2024-06-15 07:08:33
export PATH="$PATH:/Users/oakypokey/.local/bin:/usr/local/bin"
AUTO_NOTIFY_IGNORE+=("docker", "cde")

neofetch
sleep 1
clear



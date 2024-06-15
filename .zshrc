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

# Add snippets
zinit snippet OMZP::git
zinit snippet OMZP::sudo
zinit snippet OMZP:: aws
zinit snippet OMZP::command-not-found

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
zstyle ':fzf-tab:complete:cd:*' fzf-preview 'ls --color $realpath' # add fzf preview for directories
zstyle ':fzf-tab:complete:__zoxide_z:*' fzf-preview 'ls --color $realpath'

# Shell integrations
eval "$(fzf --zsh)" # fzf integration -- make sure installed via pkg manager like brew
eval "$(zoxide init --cmd cd zsh)" # add zoxide

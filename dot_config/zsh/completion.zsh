zstyle ':completion:*' matcher-list 'm:{a-z}={A-Za-z}'
zstyle ':completion:*' list-colors "${(s.:.)LS_COLORS}"
zstyle ':completion:*' menu no
zstyle ':fzf-tab:complete:cd:*' fzf-preview 'tree -L 2 -C $realpath'
zstyle ':fzf-tab:complete:__zoxide_z:*' fzf-preview 'tree -L 2 -C $realpath'

if [[ -z "$CLAUDE_SESSION" ]]; then
  alias ls='ls --color'
fi
alias python=python3
alias cde='code $(fzfg -m --preview="bat --color=always {}")'

if [[ -f "/opt/homebrew/bin/brew" ]]; then
  eval "$(/opt/homebrew/bin/brew shellenv)"
fi

brew() {
  command brew "$@"
  local status=$?

  if [[ $status -eq 0 ]]; then
    case "$1" in
      install|uninstall|remove|rm|tap|untap)
        if command -v chezmoi >/dev/null 2>&1; then
          local brewfile
          brewfile="$(chezmoi source-path ~/.Brewfile 2>/dev/null)"
          if [[ -n "$brewfile" ]]; then
            command brew bundle dump --file "$brewfile" --force --describe
          fi
        fi
        ;;
    esac
  fi

  return $status
}

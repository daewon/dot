# Shared zsh presets for this dot repo.
# Source this file from ~/.zshrc (interactive shell).

# Prevent double-loading.
if [[ -n "${DOT_ZSH_SHARED_LOADED:-}" ]]; then
  return
fi
export DOT_ZSH_SHARED_LOADED=1

# Keep PATH additions centralized and deduplicated.
typeset -gU path
path=("$HOME/.local/bin" "$HOME/bin" $path)
export PATH

# Activate mise for interactive shells when available.
if [[ -o interactive ]] && command -v mise >/dev/null 2>&1; then
  eval "$(mise activate zsh --quiet)"
fi

# Prompt preference (works after Prezto init).
if (( $+functions[prompt] )); then
  prompt skwp
fi

# History policy: large, append immediately, shared across sessions.
HISTFILE="${ZDOTDIR:-$HOME}/.zsh_history"
HISTSIZE=1000000
SAVEHIST=1000000
unsetopt APPEND_HISTORY
setopt INC_APPEND_HISTORY_TIME
setopt SHARE_HISTORY
setopt HIST_IGNORE_DUPS
setopt HIST_IGNORE_ALL_DUPS
setopt HIST_FIND_NO_DUPS
setopt HIST_SAVE_NO_DUPS
setopt HIST_EXPIRE_DUPS_FIRST
setopt HIST_REDUCE_BLANKS
setopt EXTENDED_HISTORY
setopt HIST_FCNTL_LOCK

# Quality-of-life aliases.
alias ta='tmux attach'
alias lg='lazygit'
if command -v fdfind >/dev/null 2>&1; then
  alias fd='fdfind'
elif command -v fd >/dev/null 2>&1; then
  alias fd='fd'
fi

# Git-focused aliases.
alias g='git'
alias gst='git status -sb'
alias gss='git status'
alias ga='git add'
alias gaa='git add -A'
alias gc='git commit'
alias gcm='git commit -m'
alias gca='git commit --amend'
alias gco='git checkout'
alias gcb='git checkout -b'
alias gb='git branch'
alias gd='git diff'
alias gds='git diff --staged'
alias gl='git pull --rebase --autostash'
alias gp='git push'
alias glog='git log --oneline --graph --decorate --all'

# Handy helpers.
alias ..='cd ..'
alias ...='cd ../..'
alias l='ls -alF'
alias la='ls -A'
alias ll='ls -alF'

# Optional machine-local overrides (not tracked in this repo).
if [[ -f "$HOME/.zsh.local" ]]; then
  source "$HOME/.zsh.local"
fi

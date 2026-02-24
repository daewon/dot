# Shared zsh presets for this dot repo.
# Source this file from ~/.zshrc (interactive shell).

# Prevent double-loading in the current shell only.
# Do not export this guard; exported guards leak to child shells.
if [[ -n "${__DOT_ZSH_SHARED_LOADED:-}" ]]; then
  return
fi
typeset -g __DOT_ZSH_SHARED_LOADED=1

# Keep PATH additions centralized and deduplicated.
typeset -gU path
path=("$HOME/.local/bin" "$HOME/bin" $path)
export PATH
typeset -g DOT_REPO_ROOT="${${(%):-%N}:A:h:h}"

# Some terminals/session managers keep SHELL from an older parent process.
# Normalize it for child processes spawned from this zsh session.
if [[ -n "${commands[zsh]:-}" ]]; then
  export SHELL="${commands[zsh]}"
fi

# Parent process sometimes sets no-color flags (e.g., NO_COLOR=1).
# Unset them so interactive terminal apps (Helix, etc.) keep ANSI colors.
if [[ -o interactive ]]; then
  unset NO_COLOR
  unset ANSI_COLORS_DISABLED
  unset NODE_DISABLE_COLORS
  # Some TUIs only enable 24-bit colors when COLORTERM=truecolor is set.
  if [[ -z "${COLORTERM:-}" ]] && [[ "$TERM" == *256color* ]]; then
    export COLORTERM=truecolor
  fi
fi

# Activate mise for interactive shells when available.
if [[ -o interactive ]] && command -v mise >/dev/null 2>&1; then
  eval "$(mise activate zsh --quiet)"
fi

# Prompt preference (works after Prezto init).
if (( $+functions[prompt] )); then
  prompt skwp
fi

# Enable fzf keybindings/completion in interactive TTY shells.
if [[ -o interactive ]] && [[ -t 1 ]] && command -v fzf >/dev/null 2>&1; then
  eval "$(fzf --zsh)"
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

# tmux helpers.
typeset -g DOT_TMUX_SESSION_NAME="${DOT_TMUX_SESSION_NAME:-main}"
ta() {
  local session_name="${1:-$DOT_TMUX_SESSION_NAME}"
  if ! command -v tmux >/dev/null 2>&1; then
    echo "tmux not found in PATH" >&2
    return 127
  fi
  tmux new-session -A -s "$session_name"
}

# Auto-enter tmux on first SSH login shell unless explicitly disabled.
if [[ -o interactive ]] \
  && [[ -o login ]] \
  && [[ -t 0 ]] \
  && [[ -t 1 ]] \
  && [[ -n "${SSH_CONNECTION:-${SSH_TTY:-}}" ]] \
  && [[ -z "${TMUX:-}" ]] \
  && [[ "${DOT_AUTO_TMUX_ON_SSH:-1}" == "1" ]] \
  && command -v tmux >/dev/null 2>&1; then
  ta "${DOT_AUTO_TMUX_SESSION_NAME:-$DOT_TMUX_SESSION_NAME}"
fi

# Quality-of-life aliases.
function lazygit() {
  local lazygit_bin="${commands[lazygit]:-}"
  if [[ -z "$lazygit_bin" ]]; then
    lazygit_bin="$(whence -p lazygit 2>/dev/null || true)"
  fi
  if [[ -z "$lazygit_bin" ]]; then
    echo "lazygit not found in PATH" >&2
    return 127
  fi
  env -u NO_COLOR -u ANSI_COLORS_DISABLED -u NODE_DISABLE_COLORS \
    COLORTERM=truecolor "$lazygit_bin" -ucf "$HOME/.config/lazygit/config.yml" "$@"
}
alias lg='lazygit'
if command -v dot-lazygit-theme >/dev/null 2>&1; then
  alias lgt='dot-lazygit-theme'
elif [[ -n "${DOT_REPO_ROOT:-}" ]] && [[ -x "$DOT_REPO_ROOT/scripts/lazygit-theme.sh" ]]; then
  alias lgt="$DOT_REPO_ROOT/scripts/lazygit-theme.sh"
fi
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
if ls --color=auto -d . >/dev/null 2>&1; then
  alias ls='ls --group-directories-first --color=auto -F'
elif ls -G -d . >/dev/null 2>&1; then
  alias ls='ls -G -F'
fi
alias l='ls -alF'
alias la='ls -A'
alias ll='ls -alF'

# Optional machine-local overrides (not tracked in this repo).
if [[ -f "$HOME/.zsh.local" ]]; then
  source "$HOME/.zsh.local"
fi
[ -f "$HOME/.alias" ] && source "$HOME/.alias"

export FZF_DEFAULT_OPTS="--height 100% --layout=reverse --border --bind='ctrl-o:execute(code {})'"

if ! builtin type fzf >/dev/null 2>&1; then
  return
fi

# Setup fzf
if [[ ! "$PATH" == */usr/local/opt/fzf/bin* ]]; then
  export PATH="$PATH:/usr/local/opt/fzf/bin"
fi

# Man path
if [[ ! "$MANPATH" == */usr/local/opt/fzf/man* && -d "/usr/local/opt/fzf/man" ]]; then
  export MANPATH="$MANPATH:/usr/local/opt/fzf/man"
fi

# Auto-completion
[[ $- == *i* ]] && source "/usr/local/opt/fzf/shell/completion.zsh" 2> /dev/null

# Key bindings
source "/usr/local/opt/fzf/shell/key-bindings.zsh"

alias preview="fzf --preview 'bat --theme zenburn --color \"always\" {}'"

# add support for ctrl+o to open selected file in VS Code

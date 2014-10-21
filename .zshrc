#
# Executes commands at the start of an interactive session.
#
# Authors:
#   Sorin Ionescu <sorin.ionescu@gmail.com>
#

# Source Prezto.
if [[ -s "${ZDOTDIR:-$HOME}/.zprezto/init.zsh" ]]; then
    source "${ZDOTDIR:-$HOME}/.zprezto/init.zsh"
fi

[[ -s /Users/blueiur/.nvm/nvm.sh ]] && . /Users/blueiur/.nvm/nvm.sh # This loads NVM

# Customize to your needs...

export PATH=/usr/local/bin:$PATH
for config_file ($HOME/.yadr/zsh/*.zsh) source $config_file

bindkey -e 
set -o emacs

[[ -s ".ruby-version" ]] && rvm .

# Ruby Version Manager
if [ -s ~/.rvm/scripts/rvm ] ; then

    # Prompt function. Return the full version string.
    function ruby_prompt_version_full {
        version=$(
            rvm info |
            grep -m 1 'full_version' |
            sed 's/^.*full_version:[ ]*//' |
            sed 's/["]//g'
        ) || return
        echo $version
    }

    # Prompt function. Return just the version number.
    function ruby_prompt_version {
        version=$(
            rvm info |
            grep -m 1 'version' |
            sed 's/^.*version:[ ]*//' |
            sed 's/["]//g'
        ) || return
        echo $version
    }
fi # Ruby Version Manager
# add the rvm_info_for_prompt into your prompt
# below is my full prompt

# this tests for the presence of rvm
# if its loaded, it'll add the prompt
function rvm_info_for_prompt {
    ruby_version=$(~/.rvm/bin/rvm-prompt)
    if [ -n "$ruby_version" ]; then
        echo "[$ruby_version]"
    fi
}

PATH=$PATH:$HOME/dot/script

alias vi=vim

PATH=$PATH:$HOME/.rvm/bin # Add RVM to PATH for scripting

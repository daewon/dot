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

function setjdk() {
  if [ $# -ne 0 ]; then
   removeFromPath '/System/Library/Frameworks/JavaVM.framework/Home/bin'
   if [ -n "${JAVA_HOME+x}" ]; then
    removeFromPath $JAVA_HOME
   fi
   export JAVA_HOME=`/usr/libexec/java_home -v $@`
   export PATH=$JAVA_HOME/bin:$PATH
  fi
 }
 function removeFromPath() {
  export PATH=$(echo $PATH | sed -E -e "s;:$1;;" -e "s;$1:?;;")
 }
setjdk 1.8

export SBT_OPTS="-Xmx2G -XX:+UseConcMarkSweepGC -XX:+CMSClassUnloadingEnabled -XX:MaxPermSize=2G -Xss2M  -Duser.timezone=GMT"

# Customize to your needs...

export PATH=/usr/local/bin:$PATH:~/apps/bin:
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

export PATH="$PATH:$HOME/.rvm/bin" # Add RVM to PATH for scripting
# export RUBYOPT='-w'
export JAVA_HOME=$(/usr/libexec/java_home)

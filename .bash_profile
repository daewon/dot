export GTK_IM_MODULE=ibus
export XMODIFIERS=@im=ibus
export QT_IM_MODULE=ibus

export JAVA_HOME="/opt/java"
export JAVAC=$JAVA_HOME/bin/java
export SCALA_HOME="/opt/scala"
export IO_HOME="/opt"
export MAVEN_HOME="/opt/maven"
export EMACS_HOME="/usr"
export NODE_HOME="/opt/node"


#export JAVA_HOME="/usr/lib/jvm/java-6-sun"
export CATALINA_HOME="/opt/tomcat"
export TERM="xterm-256color" 
if [ -e /usr/share/terminfo/x/xterm-256color ]; then
        export TERM='xterm-256color'
else
#        export TERM='xterm-color'
        export TERM='xterm-256color'
fi
export CVSROOT="$HOME"
export LC_ALL="ko_KR.UTF-8"

PATH=$JAVA_HOME/bin:$MAVEN_HOME/bin:$PATH:"$HOME/.cabal/bin":
PATH=$SCALA_HOME/bin:$PATH
PATH=$IO_HOME/bin:$PATH
PATH=$NODE_HOME/bin:$PATH
PATH=~/apps/sbt/bin:$PATH
export PATH

alias ssh-rep="ssh gorda@210.181.197.68"
alias ssh-dw="ssh 124.137.17.162"
alias ssh-wo="ssh snow@wo.synap.co.kr"
alias update="sudo aptitude update"
alias upgrade="sudo aptitude -y full-upgrade"
alias search="sudo aptitude search"
alias iapt="sudo aptitude install"
alias suapt="sudo aptitude"
alias sudeb="sudo gdebi"
alias ll="ls -alh"
alias ps="ps -ef"

EM="$EMACS_HOME/bin/emacs"
alias em="$EM -nw"
alias emacs="$EM"
alias cub-start="cubrid service start"
alias cub-stop="cubrid service stop"
alias sts="nohup /home/"
alias vbox="nohup VirtualBox > /dev/null &"
alias nate="nohup nateon > /dev/null &"
alias grep="egrep --color=auto"
alias egrep="egrep --color=auto"
alias ls="ls --color=auto"
alias term="nohup gnome-terminal --geometry=120X100+0+0 &"
alias sd="sudo"
alias tomstop="$CATALINA_HOME/bin/catalina.sh stop"
alias tomstart="pushd /opt/tomcat;$CATALINA_HOME/bin/catalina.sh start; popd"
alias apt="aptitude"
alias snow="cd $HOME/work/SNOW"
alias ssh-wo="ssh snow@wo.synap.co.kr"
alias ssh-daewon="ssh 124.137.17.159"
alias ssh-gw="ssh synapsoft@gw03.nhnsystem.com"
alias htop='htop -u blueiur'
alias psef='ps -ef | grep '
alias catout='tail -f -n 1000 /opt/tomcat/logs/catalina.out'
alias snsd='cd ~/work/SNSD'
alias cell='cd ~/work/CELL'
alias auto='cd ~/autocompile'
alias rep='cd ~/rep_daewon'

export EDITOR=vi

export LD_LIBRARY_PATH=$LIBPATH:./:/usr/local/lib/:/opt/lib/:/opt/sqlitejni/lib:

PS1='\[\033[01;32m\]\u\[\033[0;36m\]@\[\033[1;34m\]\h \[\033[01;33m\]\W \$ \[\033[00m\]'

export SCALA_HOME=/opt/scala
PATH=$PATH:${SCALA_HOME}/bin
export PATH

alias meminfo='echo "/proc/meminfo:"; cat /proc/meminfo; echo "/proc/swaps:"; cat /proc/swaps'
alias cpuinfo='echo "/proc/cpuinfo:"; cat /proc/cpuinfo'

[[ -s "$HOME/.rvm/scripts/rvm" ]] && source "$HOME/.rvm/scripts/rvm" # Load RVM into a shell session *as a function*

[[ -s /home/blueiur/.nvm/nvm.sh ]] && . /home/blueiur/.nvm/nvm.sh # This loads NVM

export PATH=$PATH:$HOME/apps/bin

HISTSIZE=100000000
SAVEHIST=100000000

# Add Visual Studio Code (code)
export PATH="$PATH:/Applications/Visual Studio Code.app/Contents/Resources/app/bin"
export ZPLUG_HOME=/usr/local/opt/zplug

export GRAALVM_HOME=$HOME/apps/grallvm

#export HADOOP_HOME=/Users/daewon/code/dfs/hadoop
#export HIVE_HOME=/Users/daewon/code/dfs/hive
#export HADOOP_CONF_DIR=/Users/daewon/code/dfs/yarn-conf
#export SPARK_HOME=/usr/local/Cellar/apache-spark/2.4.1/libexec

#export PATH=$PATH:$HADOOP_HOME/bin:$HIVE_HOME/bin

jabba use default

source $ZPLUG_HOME/init.zsh


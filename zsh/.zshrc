# Path to your oh-my-zsh configuration.
ZSH=$HOME/.oh-my-zsh

# Set name of the theme to load.
# Look in ~/.oh-my-zsh/themes/
# Optionally, if you set this to "random", it'll load a random theme each
# time that oh-my-zsh is loaded.
ZSH_THEME="pygmalion"

# Example aliases
# alias zshconfig="mate ~/.zshrc"
# alias ohmyzsh="mate ~/.oh-my-zsh"
alias tmux="tmux -2"
alias nautilus="nautilus --no-desktop"
alias vi=vim
alias journal="if [[ -a ~/Projects/journal ]]; then vim ~/Projects/journal/$(date +%Y-%m).md; else vim /projects/journal/$(date +%Y-%m).md; fi"
#alias vim="/Applications/MacVim.app/Contents/MacOS/Vim"

# Set to this to use case-sensitive completion
# CASE_SENSITIVE="true"

# Comment this out to disable weekly auto-update checks
# DISABLE_AUTO_UPDATE="true"

# Uncomment following line if you want to disable colors in ls
# DISABLE_LS_COLORS="true"

# Uncomment following line if you want to disable autosetting terminal title.
# DISABLE_AUTO_TITLE="true"

# Uncomment following line if you want red dots to be displayed while waiting for completion
# COMPLETION_WAITING_DOTS="true"

# Which plugins would you like to load? (plugins can be found in ~/.oh-my-zsh/plugins/*)
# Custom plugins may be added to ~/.oh-my-zsh/custom/plugins/
# Example format: plugins=(rails git textmate ruby lighthouse)
plugins=(git docker docker-compose)

source $ZSH/oh-my-zsh.sh

# Customize to your needs...
export PATH=$PATH:/usr/local/bin:/usr/local/git/bin/:/Applications/Xcode.app/Contents/Developer/usr/bin:/var/npm/bin
#export NODE_PATH=/usr/local/lib/node_modules

# UTF-8
LC_CTYPE="en_US.UTF-8"
LANG="en_US.UTF-8"

if [[ -s $HOME/google-cloud-sdk ]]; then
  # The next line updates PATH for the Google Cloud SDK.
  source $HOME/google-cloud-sdk/path.zsh.inc
fi

if [ "$TMUX" = "" ]; then tmux attach; fi

if [[ -a ~/.ssh/id_rsa ]]; then
  eval `ssh-agent -s` && ssh-add ~/.ssh/id_rsa
else
  eval `ssh-agent -s` && ssh-add /keys/id_rsa
fi

export GOPATH=$HOME/.go
PATH=$PATH:$GOPATH/bin

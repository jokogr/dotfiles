# ~/.zshrc
# vim:set et sw=2:

# Prompt
autoload -Uz colors && colors

autoload -Uz vcs_info
zstyle ':vcs_info:*' enable git hg svn
zstyle ':vcs_info:*' check-for-changes true
zstyle ':vcs_info:*' get-revision true
zstyle ':vcs_info:*' unstagedstr '!'
zstyle ':vcs_info:hg*' branchformat "%b"
zstyle ':vcs_info:hg*' hgrevformat "%r"
zstyle ':vcs_info:hg*' get-unapplied true
zstyle ':vcs_info:hg*' formats "(%s) [%i%u %b %m]"
zstyle ':vcs_info:hg*' actionformats "(%s|%a) [%i%u %b %m]"
zstyle ':vcs_info:hg*' patch-format "mq(%g):%n/%c %p"
zstyle ':vcs_info:hg*' nopatch-format "mq(%g):%n/%c %p"

precmd() { vcs_info }
setopt prompt_subst
PROMPT='%{$fg[green]%}%n@%m%{$reset_color%} %{$fg[blue]%}%~%{$reset_color%}\
 ${vcs_info_msg_0_}
%# '

# History
HISTSIZE=100
setopt histignoredups histreduceblanks incappendhistory

# Misc
setopt extendedglob

# Homeshick
source $HOME/.homesick/repos/homeshick/homeshick.sh
typeset -U fpath
fpath+=$HOME/.homesick/repos/homeshick/completions

# Completion
zstyle ':completion:*' menu select
zstyle ':completion:*' use-cache on
zstyle ':completion:*' cache-path ~/.zsh/cache
zstyle :compinstall filename ~/.zshrc

autoload -Uz compinit
compinit

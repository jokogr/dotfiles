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
HISTSIZE=200
HISTFILE=~/.zsh_history
SAVEHIST=200
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

compdef _joko joko

_joko() {
  local cmd=$(basename $words[1])
  if [[ $CURRENT = 2 ]]; then
    local tmp
    tmp=($(grep '^  [a-z-]*[|)]' "$HOME/bin/$cmd" | sed -e 's/).*//' | tr '|' ' '))
    _describe -t commands "${words[1]} command" tmp --
  fi
}

alias gst='git status'

# Keyboard and keybindings
bindkey -v
bindkey "^R" history-incremental-search-backward

typeset -A key
key[Home]=${terminfo[khome]}
key[End]=${terminfo[kend]}
key[Insert]=${terminfo[kich1]}
key[Delete]=${terminfo[kdch1]}
key[Up]=${terminfo[kcuu1]}
key[Down]=${terminfo[kcud1]}
key[Left]=${terminfo[kcub1]}
key[Right]=${terminfo[kcuf1]}
key[PageUp]=${terminfo[kpp]}
key[PageDown]=${terminfo[knp]}

# setup key accordingly
[[ -n "${key[Home]}"     ]]  && bindkey  "${key[Home]}"     beginning-of-line
[[ -n "${key[End]}"      ]]  && bindkey  "${key[End]}"      end-of-line
[[ -n "${key[Insert]}"   ]]  && bindkey  "${key[Insert]}"   overwrite-mode
[[ -n "${key[Delete]}"   ]]  && bindkey  "${key[Delete]}"   delete-char
[[ -n "${key[Up]}"       ]]  && bindkey  "${key[Up]}"       up-line-or-history
[[ -n "${key[Down]}"     ]]  && bindkey  "${key[Down]}"     down-line-or-history
[[ -n "${key[Left]}"     ]]  && bindkey  "${key[Left]}"     backward-char
[[ -n "${key[Right]}"    ]]  && bindkey  "${key[Right]}"    forward-char
[[ -n "${key[PageUp]}"   ]]  && bindkey  "${key[PageUp]}"   beginning-of-buffer-or-history
[[ -n "${key[PageDown]}" ]]  && bindkey  "${key[PageDown]}" end-of-buffer-or-history

# Finally, make sure the terminal is in application mode, when zle is
# active. Only then are the values from $terminfo valid.
if (( ${+terminfo[smkx]} )) && (( ${+terminfo[rmkx]} )); then
    function zle-line-init () {
        printf '%s' "${terminfo[smkx]}"
    }
    function zle-line-finish () {
        printf '%s' "${terminfo[rmkx]}"
    }
    zle -N zle-line-init
    zle -N zle-line-finish
fi

test -f "$HOME/.zshrc.local" && . "$HOME/.zshrc.local"

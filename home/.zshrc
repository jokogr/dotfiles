# ~/.zshrc
# vim:set et sw=2:

. "$HOME/.shrc"

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
fpath+=$HOME/.zfunctions

autoload -U promptinit; promptinit
PURE_GIT_PULL=0
PURE_GIT_UNTRACKED_DIRTY=0
prompt pure

# Completion
zstyle ':completion:*' menu select
zstyle ':completion:*' use-cache on
zstyle ':completion:*' cache-path ~/.zsh/cache
zstyle ':completion:*:(rm|vimdiff):*' ignore-line yes
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

fd() {
  DIR=`find ${1:-*} -path '*/\.*' -prune -o -type d -print 2> /dev/null | fzf-tmux` \
    && cd "$DIR"
}

if [ -f "$HOME/.homesick/repos/dotfiles/zsh/autopair/autopair.zsh" ]; then
  source "$HOME/.homesick/repos/dotfiles/zsh/autopair/autopair.zsh"
fi

test -d "$HOME/.fzf/shell" \
  && . "$HOME/.fzf/shell/completion.zsh" \
  && . "$HOME/.fzf/shell/key-bindings.zsh"

test -f "$HOME/.zshrc.local" && . "$HOME/.zshrc.local"

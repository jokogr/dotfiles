#!/bin/sh

export LC_ALL=en_US.UTF-8
export LANG=en_US.UTF-8

if [ -r "$HOME/.env.local" ]; then
  . "$HOME/.env.local"
  vars=`awk -F= '/^[A-Z].*=/ { print $1 }' "$HOME/.env.local"`
  [ -z "$vars" ] || eval "export $vars"
fi
unset vars

ENV="$HOME/.shrc"
BASH_ENV="$HOME/.zshenv"
export ENV BASH_ENV

for dir in /usr/local/bin "$HOME/bin"; do
  if [ -d "$dir" ]; then
    PATH="""${dir}:`echo "$PATH"|sed -e "s#${dir}:##"`"
  fi
done

for dir in "$HOME/.node_modules/bin" "$HOME/.fzf/bin"; do
  if [ -d "$dir" ]; then
    case ":$PATH:" in
      *:"$dir":*) ;;
      *) PATH="$PATH:$dir" ;;
    esac
  fi
done

unset dir
export PATH

if [ -d "$HOME/.node_modules" ]; then
  NPM_CONFIG_PREFIX="$HOME/.node_modules"
  export NPM_CONFIG_PREFIX
fi

# set up SSH agent socket symlink
export SSH_AUTH_SOCK_LINK="/tmp/ssh-$USER/agent"
if ! [ -r $(readlink -m $SSH_AUTH_SOCK_LINK) ] && [ -r $SSH_AUTH_SOCK ]; then
	mkdir -p "$(dirname $SSH_AUTH_SOCK_LINK)" &&
	chmod go= "$(dirname $SSH_AUTH_SOCK_LINK)" &&
	ln -sfn $SSH_AUTH_SOCK $SSH_AUTH_SOCK_LINK
fi


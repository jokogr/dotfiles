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

if [ -f "$HOME/.nix-profile/etc/profile.d/hm-session-vars.sh" ]; then
  . "$HOME/.nix-profile/etc/profile.d/hm-session-vars.sh"
fi

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

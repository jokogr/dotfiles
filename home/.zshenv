#! sh

ENV="$HOME/.shrc"
BASH_ENV="$HOME/.zshenv"
export ENV BASH_ENV

for dir in /usr/local/bin "$HOME/bin"; do
  if [ -d "$dir" ]; then
    PATH="""${dir}:`echo "$PATH"|sed -e "s#${dir}:##"`"
  fi
done

for dir in "$HOME/.node_modules/bin"; do
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



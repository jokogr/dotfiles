#!/bin/bash -ex
# vim:set et sw=2

# This is a bootstrap script which installs homeshick and my dotfiles to the
# current account.

git clone https://github.com/andsens/homeshick.git \
  $HOME/.homesick/repos/homeshick
source $HOME/.homesick/repos/homeshick/homeshick.sh

homeshick --batch clone https://bitbucket.org/joko/dotfiles

# Initialize vundle
homeshick cd dotfiles
git submodule init
git submodule update

echo "Where are you installing me?"
echo "1. Linux Server (default)"
echo "2. Linux Workstation"
echo "3. OSX"
echo -n "Please enter your choice: "
read swo </dev/tty
case "$swo" in
	2)
		git checkout linux-workstation
		;;
	3)
		git checkout osx
		;;
	*)
		;;
esac

cd -
homeshick link --force

# Change the dotfiles repository URL to SSH for future edits
homeshick cd dotfiles
git remote set-url origin git@bitbucket.org:joko/dotfiles.git

# Update the vim plugins
vim +PluginInstall +qall

cd -

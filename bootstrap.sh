#!/bin/bash -ex
# vim:set et sw=2

# This is a bootstrap script which installs homeshick and my dotfiles to the
# current account.

git clone https://git.joko.gr/joko/homeshick.git \
  $HOME/.homesick/repos/homeshick
source $HOME/.homesick/repos/homeshick/homeshick.sh

homeshick --batch clone https://git.joko.gr/joko/dotfiles.git

# Initialize vundle
homeshick cd dotfiles
git submodule init
git submodule update

if [ "$#" -eq 1 ]; then
	swo=$1
else
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
fi

cd -
homeshick link --force

# Change the dotfiles repository URL to SSH for future edits
homeshick cd dotfiles
git remote set-url origin gitlab@git.joko.gr:joko/dotfiles.git

# Update the vim plugins
vim +PluginInstall +qall

cd -

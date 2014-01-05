#!/bin/bash -ex
# vim:set et sw=2

# This is a bootstrap script which installs homeshick and my dotfiles to the
# current account.

git clone https://github.com/andsens/homeshick.git \
  $HOME/.homesick/repos/homeshick
source $HOME/.homesick/repos/homeshick/homeshick.sh

homeshick --batch clone https://bitbucket.org/joko/dotfiles

echo "Where are you installing me?"
echo "1. Linux Server (default)"
echo "2. Linux Workstation"
echo "3. OSX"
echo -n "Please enter your choice: "
read swo
case $swo in
	"2")
		homeshick cd dotfiles
		git checkout linux-workstation
		cd -
		;;
	"3")
		homeshick cd dotfiles
		git checkout osx
		cd -
		;;
	*)
		;;
esac

homeshick link --force

# Change the dotfiles repository URL to SSH for future edits
homeshick cd dotfiles
git remote set-url origin git@bitbucket.org:joko/dotfiles.git
cd -

#!/bin/bash -ex
# vim:set et sw=2

# This is a bootstrap script which installs homeshick and my dotfiles to the
# current account.

git clone git://github.com/andsens/homeshick.git \
  $HOME/.homesick/repos/homeshick
source $HOME/.homesick/repos/homeshick/homeshick.sh

homeshick --batch clone https://git.joko.gr/joko/dotfiles.git

# Initialize vundle
homeshick cd dotfiles

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
		homeshick --batch clone https://git.joko.gr/joko/vimperator-dotfiles.git
		homeshick cd vimperator-dotfiles
		git remote set-url origin ssh://git@git.joko.gr:10022/joko/vimperator-dotfiles.git
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
git remote set-url origin ssh://git@git.joko.gr:10022/joko/dotfiles.git

# Install vim-plug
curl -fLo ~/.vim/autoload/plug.vim --create-dirs \
	https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
vim +PlugInstall +qall

# Setup neovim
mkdir -p $HOME/.config
ln -s $HOME/.vim $HOME/.config/nvim
ln -s $HOME/.vimrc $HOME/.config/nvim/init.vim

cd -

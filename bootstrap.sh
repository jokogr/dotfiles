#!/bin/bash -ex
# vim:set et sw=2

# This is a bootstrap script which installs homeshick and my dotfiles to the
# current account.

git clone https://github.com/andsens/homeshick.git \
  $HOME/.homesick/repos/homeshick
source $HOME/.homesick/repos/homeshick/homeshick.sh

homeshick --batch clone https://bitbucket.org/joko/dotfiles
homeshick link --force

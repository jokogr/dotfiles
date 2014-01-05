# JoKo's dotfiles

This is my main repository of the dotfiles I use on various systems. I use
[homeshick](https://github.com/andsens/homeshick) to keep my dotfiles
up-to-date.

In order to simplify and optimize the dotfiles, I prefer to keep the following
branches:

* **base** - this is the base branch that every other branch is based on
* **master** - to be used on Linux servers
* **linux-workstation** - built on top of the *master* branch, it contains extra
  configuration for GUI apps
* **osx** - to be used on OS X systems

## Installation

In order to bootstrap directly, run the following command:
```text
curl -sL https://bitbucket.org/joko/dotfiles/raw/master/bootstrap.sh \
| /bin/bash -ex
```

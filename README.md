# JoKo's dotfiles

This is my main repository of the dotfiles I use on various systems. I use
[homeshick](https://github.com/andsens/homeshick) to keep my dotfiles
up-to-date.

In order to simplify and optimize the dotfiles, I prefer to keep the following
branches:

* **base** - this is the base branch that every other branch is based on (the
  branch with the most commits)
* **master** - to be used on Linux servers (the mostly used branch)
* **linux-workstation** - built on top of the *master* branch, it contains extra
  configuration for GUI apps
* **osx** - to be used on OS X systems

## Installation

In order to bootstrap directly, run the following command:
```text
curl -sL https://git.joko.gr/joko/dotfiles/raw/base/bootstrap.sh \
| /usr/bin/env bash -ex
```
Follow the instructions.

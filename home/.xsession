#!/bin/sh
# vim:set et sw=2:

xsetroot -cursor_name left_ptr

if [ -x /usr/bin/ssh-agent -a -z "$SSH_AUTH_SOCK" ]; then
  sshagent="/usr/bin/ssh-agent --"
fi

for wm in xmonad openbox xterm; do
  [ -x "`which $wm 2>/dev/null`" ] && exec $sshagent $wm
done

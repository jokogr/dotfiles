#!/bin/sh
# vim:set et sw=2:

xsetroot -cursor_name left_ptr

setxkbmap "us,gr" -option terminate:ctrl_alt_bksp,grp:alt_space_toggle

if [ -x /usr/bin/ssh-agent -a -z "$SSH_AUTH_SOCK" ]; then
  sshagent="/usr/bin/ssh-agent --"
fi

[ ! -x "`which pulseaudio 2>/dev/null`" ] || pulseaudio --start

for wm in xmonad openbox xterm; do
  [ -x "`which $wm 2>/dev/null`" ] && exec $sshagent $wm
done

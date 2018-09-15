#!/bin/sh
# vim:set et sw=2:

xsetroot -cursor_name left_ptr

setxkbmap "us,gr" -option terminate:ctrl_alt_bksp,grp:alt_space_toggle,ctrl:nocaps

[ ! -x "`which bindkeys 2>/dev/null`" ] || xbindkeys -n &
[ ! -x "`which xcape 2>/dev/null`" ] || xcape -e 'Control_L=Escape' &
[ ! -x "`which kbdd 2>/dev/null`" ] || kbdd -n &

[ ! -x "`which pulseaudio 2>/dev/null`" ] || pulseaudio --start

for wm in xmonad openbox xterm; do
  [ -x "`which $wm 2>/dev/null`" ] && exec $wm
done

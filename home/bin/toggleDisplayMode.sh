#!/usr/bin/env zsh
#
# File:         toggleDisplayMode.sh
# Author:       Ioannis Koutras <ioannis.koutras@gmail.com>
# Description:  This script selects automatically the output between multiple
#               displays.
# Dependencies: awk, xrandr and zsh
#
#
# TODO:
#
# * Use an indicator of the change.
# * Support mirroring displays
# * Support extending displays

xrandr_output="`xrandr -q`"

# available_outputs variable gets the disconnected ones too
available_outputs=(`echo $xrandr_output | awk '{if ($0 ~ "connected") {print $1;}}'`)
connected_outputs=(`echo $xrandr_output | awk '{if ($0 ~ " connected") {print $1;}}'`)

# activate_single_output() has one argument, the output which gets activated
activate_single_output () {
  XRANDR_COMMAND="xrandr"
  for current_output in $available_outputs; do
    if [ "$current_output" = "$1" ]; then
      XRANDR_COMMAND="${XRANDR_COMMAND} --output ${current_output} --primary --auto"
    else
      XRANDR_COMMAND="${XRANDR_COMMAND} --output ${current_output} --off"
    fi
  done
  eval ${XRANDR_COMMAND}
  pkill status.sh; pkill dzen2; pkill stalonetray; xmonad --restart
  exit
}

active_outputs=(`echo $xrandr_output | \
  awk '/ connected/ {current_output=$1;} /*/ {print current_output}'`)

# Activate next connected output
if ((${#active_outputs} == 1)); then
  (( next_index = ${connected_outputs[(i)${active_outputs[1]}]} + 1 ))
  if (($next_index > $#connected_outputs)); then
    next_index=1
  fi
  activate_single_output $connected_outputs[next_index]
else
  activate_single_output ${active_outputs[1]}
fi

#!/bin/sh

# This script outputs the starting resolution point of the primary monitor and
# its total width e.g. "1920 2560".

xrandr -q | sed -n 's/.*primary\ \([0-9]\+\)x[0-9]\++\([0-9]\+\).*/\2 \1/p'

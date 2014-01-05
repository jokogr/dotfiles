#!/bin/sh

xrandr -q | sed -n 's/.*connected\ \([0-9]\+\)x[0-9]\++0+0.*/\1/p' | tail -n 1

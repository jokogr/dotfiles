#!/usr/bin/env zsh

INTERVAL=5

printCPUInfo() {
  echo -n "$CPUFreq GHz"
  return
}

printTempInfo() {
  echo -n "$CPUTemp°"
}

printDate() {
  echo -n "$(date +'%Y.%m.%d %H:%M')"
  return
}

printSpace() {
  echo -n " | "
  return
}

printBar() {
  while true; do
    read CPUFreq CPUTemp
    printCPUInfo
    printSpace
    printTempInfo
    printSpace
    printDate
    echo
    sleep $INTERVAL
  done
  return
}

conky -c ~/.xmonad/conkyrc -u $INTERVAL | printBar

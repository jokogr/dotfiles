#!/bin/zsh

INTERVAL=5

printCPUInfo() {
  echo -n "$CPUFreq GHz"
  return
}

printTempInfo() {
  echo -n "$CPUTemp° / $(aticonfig --odgt | tail -n 1 | awk '{ print $(NF-1) }')°"
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
    read CPUFreq CPUTemp GPUTemp
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

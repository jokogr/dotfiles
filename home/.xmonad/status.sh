#!/bin/zsh

INTERVAL=5

printCPUInfo() {
  echo -n "$CPUFreq GHz"
  return
}

printBattery() {
  echo -n "$(cat /sys/class/power_supply/BAT0/capacity)%"
  return
}

printTempInfo() {
  echo -n "$CPUTemp° / $GPUTemp°"
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
    printBattery
    printSpace
    printDate
    echo
    sleep $INTERVAL
  done
  return
}

conky -c ~/.xmonad/conkyrc -u $INTERVAL | printBar

#!/bin/bash

# This is a simple utility to script the jailbreak
# of iPod Touch or iPhone
#
# You need to do the following to make this work
#
# 1) Copy blackra1n (the tool used to jailbreak iPhone/iPod Touch) to the
#    Mac's Application folder. 
#
# 2) Go to "System Preferences", select "Universal Access"
#    then click on "Enable access for assistive devices."

kill -HUP `ps -axwwwww | grep blackra1n | grep -v grep | awk '{print $1}'`
osascript /builds/autobuild/configs/autobuild/zifnab/jailbreak.scpt
sleep 60
kill -HUP `ps -axwwwww | grep blackra1n | grep -v grep | awk '{print $1}'`

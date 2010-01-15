#!/bin/sh
echo "`date`" > ~/last_run
perl /builds/autobuild/autobuild.pl /builds/autobuild/configs/autobuild/zifnab/gcc32.xml
perl /builds/autobuild/autobuild.pl /builds/autobuild/configs/autobuild/zifnab/gcc64.xml
sudo shutdown -h now


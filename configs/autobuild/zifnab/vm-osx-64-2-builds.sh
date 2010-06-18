#!/bin/sh
echo "`date`" > ~/last_run
perl /builds/autobuild/autobuild.pl -V /builds/autobuild/configs/autobuild/zifnab/icc64.xml
perl /builds/autobuild/autobuild.pl -V /builds/autobuild/configs/autobuild/zifnab/gcc64.xml
sudo shutdown -h now


#!/bin/sh
echo "`date`" > ~/last_run
sudo /opt/icecream/sbin/iceccd &
export ICECC_VERSION=/Users/bczar/9729ecda0c3e2a5ab080917526226623.tar.gz
perl /builds/autobuild/autobuild.pl -V /builds/autobuild/configs/autobuild/zifnab/gcc32.xml
perl /builds/autobuild/autobuild.pl -V /builds/autobuild/configs/autobuild/zifnab/gcc64.xml
sudo shutdown -h now


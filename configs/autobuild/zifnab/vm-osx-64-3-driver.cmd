#!/bin/sh
svn up  /builds/autobuild
export PATH=/opt/icecream/bin:$PATH
sudo /opt/icecream/sbin/iceccd &
export ICECC_VERSION=/Users/bczar/9729ecda0c3e2a5ab080917526226623.tar.gz
exec /builds/autobuild/configs/autobuild/zifnab/vm-osx-64-3-builds.sh

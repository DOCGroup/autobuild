#!/bin/sh

git pull  /builds/autobuild
exec /builds/autobuild/autobuild.pl /builds/autobuild/configs/autobuild/abdul/iOS_7_Simulator.xml


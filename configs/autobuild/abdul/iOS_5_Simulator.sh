#!/bin/sh

svn up /builds/autobuild
exec /builds/autobuild/autobuild.pl /builds/autobuild/configs/autobuild/abdul/iOS_5_Simulator.xml


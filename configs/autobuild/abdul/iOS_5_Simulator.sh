#!/bin/sh

svn up /builds/autobuild
exec /builds/autobuild/autobuild.pl -v2 iOS_5_Simulator.xml


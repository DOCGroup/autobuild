#!/bin/sh

svn up /builds/autobuild
exec /builds/autobuild/autobuild.pl iOS_5_Simulator.xml


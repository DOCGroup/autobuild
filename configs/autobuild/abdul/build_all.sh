#!/bin/sh
#
# $Id$
#

cd /builds/autobuild

svn up

/usr/bin/perl /builds/autobuild/autobuild.pl /builds/autobuild/configs/autobuild/abdul/lion_full_llvm.xml
/usr/bin/perl /builds/autobuild/autobuild.pl /builds/autobuild/configs/autobuild/abdul/lion_full_static_llvm.xml
/usr/bin/perl /builds/autobuild/autobuild.pl /builds/autobuild/configs/autobuild/abdul/iOS_5_Simulator.xml
/usr/bin/perl /builds/autobuild/autobuild.pl /builds/autobuild/configs/autobuild/abdul/iOS_5_Hardware.xml


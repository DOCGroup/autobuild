#!/bin/sh
#
# $Id$
#

cd /builds/autobuild

git pull

/usr/bin/perl /builds/autobuild/autobuild.pl /builds/autobuild/configs/autobuild/abdul/mavericks_full_llvm.xml
/usr/bin/perl /builds/autobuild/autobuild.pl /builds/autobuild/configs/autobuild/abdul/mavericks_full_static_llvm.xml
/usr/bin/perl /builds/autobuild/autobuild.pl /builds/autobuild/configs/autobuild/abdul/iOS_7_Simulator.xml
/usr/bin/perl /builds/autobuild/autobuild.pl /builds/autobuild/configs/autobuild/abdul/iOS_7_Hardware.xml


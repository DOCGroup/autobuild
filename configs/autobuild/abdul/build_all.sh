#!/bin/sh
#
# $Id$
#

cd /builds/autobuild

git pull

/usr/bin/perl /builds/autobuild/autobuild.pl /builds/autobuild/configs/autobuild/abdul/mountain_lion_full_llvm.xml
/usr/bin/perl /builds/autobuild/autobuild.pl /builds/autobuild/configs/autobuild/abdul/mountain_lion_full_static_llvm.xml
/usr/bin/perl /builds/autobuild/autobuild.pl /builds/autobuild/configs/autobuild/abdul/iOS_6_Simulator.xml
/usr/bin/perl /builds/autobuild/autobuild.pl /builds/autobuild/configs/autobuild/abdul/iOS_6_Hardware.xml


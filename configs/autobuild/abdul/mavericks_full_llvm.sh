#!/bin/sh
#
# $Id$
#

cd /builds/autobuild

git pull

exec /usr/bin/perl /builds/autobuild/autobuild.pl \
                             /builds/autobuild/configs/autobuild/abdul/mavericks_full_llvm.xml


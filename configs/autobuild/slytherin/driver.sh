#!/bin/sh
#
# $Id$
#

BUILDDIR=/project/slytherin/acebuild

exec /usr/bin/perl $BUILDDIR/autobuild/autobuild.pl \
                             $BUILDDIR/autobuild/configs/autobuild/slytherin/OpenBSD_Core.xml 2>&1


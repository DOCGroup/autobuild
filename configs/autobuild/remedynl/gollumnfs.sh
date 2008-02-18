#!/bin/sh
#
# $Id$
#
BUILDROOT=/dnfs1/openvms/v82x

cd $BUILDROOT

perl -X -I$BUILDROOT/autobuild $BUILDROOT/autobuild/autobuild.pl $BUILDROOT/autobuild/configs/autobuild/remedynl/gollumnfs.xml


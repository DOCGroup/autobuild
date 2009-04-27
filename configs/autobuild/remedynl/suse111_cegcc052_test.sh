#!/bin/sh
#
# $Id$
#
svn up
exec /usr/bin/perl /home/build/ACE/autobuild/autobuild.pl /home/build/ACE/autobuild/configs/autobuild/remedynl/suse111_cegcc052_test.xml

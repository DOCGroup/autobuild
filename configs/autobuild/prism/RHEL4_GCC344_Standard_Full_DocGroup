#!/bin/sh
# $Id$
#
PATH=/usr/local/bin:$PATH;export PATH
#
echo "Updating doc_autobuild"
cd /home/tao/doc_autobuild
svn update autobuild
svn status autobuild
cd /home/tao/rhel4/doc_scoreboard/Full
#
perl /home/tao/doc_autobuild/autobuild/autobuild.pl /home/tao/doc_autobuild/autobuild/configs/autobuild/prism/RHEL4_GCC344_Standard_Full_DocGroup.xml

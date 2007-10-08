#!/bin/sh
# $Id$
#
PATH=/usr/local/bin:$PATH;export PATH
#
echo [`/bin/date`]: Updating doc_autobuild
cd /home/tao/doc_autobuild
svn update autobuild
cd /home/tao/rhel4/doc_scoreboard/gcc344/standard
#
echo [`/bin/date`]: Starting RHEL4_GCC344_Standard_Full_DocGroup build
perl /home/tao/doc_autobuild/autobuild/autobuild.pl /home/tao/doc_autobuild/autobuild/configs/autobuild/prism/RHEL4_GCC344_Standard_Full_DocGroup.xml
echo [`/bin/date`]: Finished

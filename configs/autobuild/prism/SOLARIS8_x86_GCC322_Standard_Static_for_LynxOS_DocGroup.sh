#!/bin/sh
# $Id$
#
PATH=/usr/local/bin:$PATH; export PATH
#
# Update the doc_autobuild scripts.
echo "Updating doc_autobuild"
cd /usr/users/tao/doc_autobuild
svn update autobuild
svn status autobuild
cd /usr/users/tao/ultra6/doc_scoreboard/native_gcc322/standard/static
#
# build ACE, tao_idl and gperf statically on ultra6 with gcc 3.2.2
echo "Building ACE, tao_idl and gperf statically on ultra6 with gcc 3.2.2"
/usr/local/bin/perl /usr/users/tao/doc_autobuild/autobuild/autobuild.pl /usr/users/tao/doc_autobuild/autobuild/configs/autobuild/prism/SOLARIS8_x86_GCC322_Standard_Static_for_LynxOS_DocGroup.xml
#
echo "Triggering Build of ACE and TAO on ultra5 with LynxOS x86 gcc 3.2.2 cross compiler"
/usr/users/tao/doc_autobuild/autobuild/configs/autobuild/prism/LYNXOS4_x86_GCC322_Standard_Dynamic_DocGroup
exit

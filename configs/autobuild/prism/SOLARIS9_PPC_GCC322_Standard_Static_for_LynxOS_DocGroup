#!/bin/sh
# $Id$
#
echo "Updating doc_autobuild"
cd /usr/users/tao/doc_autobuild
/usr/local/bin/svn update autobuild
/usr/local/bin/svn status autobuild
cd /usr/users/tao/ultra4/doc_scoreboard/native_gcc322/standard/static
#
# build ACE, tao_idl and gperf statically on ultra4 with gcc 3.2.2
echo "Building ACE, tao_idl and gperf native statically on ultra4 with gcc 3.2.2"
/usr/bin/perl /usr/users/tao/doc_autobuild/autobuild/autobuild.pl /usr/users/tao/doc_autobuild/autobuild/configs/autobuild/prism/SOLARIS9_PPC_GCC322_Standard_Static_for_LynxOS_DocGroup.xml
#
echo "Triggering Build of ACE and TAO on ultra4 with LynxOS PPC gcc 3.2.2 cross compiler"
/usr/users/tao/doc_autobuild/autobuild/configs/autobuild/prism/LYNXOS4_PPC_GCC322_Standard_Dynamic_DocGroup
exit

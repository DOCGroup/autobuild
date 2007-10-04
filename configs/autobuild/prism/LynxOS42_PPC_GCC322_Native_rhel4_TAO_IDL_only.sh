#!/bin/sh
# $Id$
#
if /usr/bin/test -f /home/tao/rhel4/doc_scoreboard/native_gcc322/standard/.disable; then echo [`/bin/date`]: Native compiler tao_idl build already in progress or locked-up; exit 1; fi
if /usr/bin/test -f /home/tao/rad1/doc_scoreboard/lynxos42_ppc_gcc322/standard/.disable; then echo [`/bin/date`]: LynxOS4.2 Cross compiler build already in progres or locked-up; exit 2; fi
#
echo [`/bin/date`]: Updating doc_autobuild
. /home/tao/cvsnew
cd /home/tao/doc_autobuild
/usr/local/bin/svn update autobuild
cd /home/tao/rad1/doc_scoreboard/native_gcc322/standard
#
# build ACE, tao_idl and gperf statically on rhel4 with gcc 3.2.2
echo [`/bin/date`]: Building ACE, tao_idl and gperf native statically on rhel4 with gcc 3.2.2
/usr/bin/perl /home/tao/doc_autobuild/autobuild/autobuild.pl /home/tao/doc_autobuild/autobuild/configs/autobuild/prism/LynxOS42_PPC_GCC322_Native_rhel4_TAO_IDL_only.xml
#
echo [`/bin/date`]: Triggering Build of ACE and TAO on rhel4 with LynxOS4.2 PPC gcc 3.2.2 cross compiler
/home/tao/doc_autobuild/autobuild/configs/autobuild/prism/LynxOS42_PPC_GCC322_Standard.sh
exit

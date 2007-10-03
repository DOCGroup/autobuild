#!/bin/sh
# $Id$
#
if /usr/bin/test -f /home/tao/rad1/doc_scoreboard/lynxos42_ppc_gcc322/standard/.disable; then echo [`/bin/date`]: LynxOS4.2 Cross compiler build already in progres or locked-up; exit 2; fi
PATH=/usr/local/bin:$PATH;export PATH
#
echo [`/bin/date`]: Updating doc_autobuild
. /home/tao/cvsnew
cd /usr/users/tao/doc_autobuild
svn update autobuild
cd /usr/users/tao/rad1/doc_scoreboard/lynxos42_ppc_gcc322/standard
#
# build ACE and TAO on rhel4 with LynxOS42 PPC gcc 3.2.2 cross compiler
# Sets ENV_PREFIX=/usr/local/lynx/4.0.0/ppc-322
echo [`/bin/date`]: Building ACE and TAO on rhel4 with LynxOS4.2 PPC gcc 3.2.2 cross compiler
/usr/bin/perl /usr/users/tao/doc_autobuild/autobuild/autobuild.pl /usr/users/tao/doc_autobuild/autobuild/configs/autobuild/prism/LynxOS42_PPC_GCC322_Standard.xml
#
echo [`/bin/date`]: Triggering rad1 to run tests
/usr/bin/nohup /usr/bin/ssh rad1 /bin/nohup /usr/users/tao/doc_autobuild/autobuild/configs/autobuild/prism/LynxOS42_PPC_GCC322_Standard_Tests_Trigger.sh
echo [`/bin/date`]: Back on rhel4, finished
exit

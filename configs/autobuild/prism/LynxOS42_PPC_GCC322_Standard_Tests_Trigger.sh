#!/bin/sh
# $Id$
#
if /bin/test -f /usr/users/tao/rad1/doc_scoreboard/lynxos42_ppc_gcc322/standard/.disable; then echo [`/bin/date`]: .disable exists, previous tests still running; exit; fi
#
echo [`/bin/date`]: Triggering detached LynxOS4_PPC_GCC322_Standard_Tests on rad1
/bin/nohup /usr/users/tao/doc_autobuild/autobuild/configs/autobuild/prism/LynxOS42_PPC_GCC322_Standard_Tests.sh > /usr/users/tao/rad1/log/LynxOS42_PPC_GCC322_Standard_Tests.log 2>&1 < /dev/null &
echo [`/bin/date`]: Ok, bye for now.
exit

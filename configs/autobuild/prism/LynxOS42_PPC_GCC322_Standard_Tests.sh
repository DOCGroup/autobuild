#!/bin/sh
# $Id$
#
PATH=/usr/local/bin:$PATH:.; export PATH
#
echo [`/bin/date`]: Copying ACE_wrappers ultra4 cross build
cd /home/tao/rad1/doc_scoreboard/lynxos42_ppc_gcc322/standard
if [ -e .disable ]; then echo ".disable exists"; exit; fi
if scp rhel4:rad1/doc_scoreboard/lynxos42_ppc_gcc322/standard/cross_tests.tar .
then
  echo [`/bin/date`]: Installing cross build
  tar -xf cross_tests.tar
  rm -f cross_tests.tar
  if test -e ACE_wrappers/TAO/tests/Portable_Interceptors/Processing_Mode_Policy/Collocated/PI_ProcMode_Collocated_Tes
  then
    echo [`/bin/date`]: TAR truncated the problem filename again (tao151/TAO/tests/Portable_Interceptors/Processing_Mode_Policy/Collocated/PI_ProcMode_Collocated_Test)
    mv ACE_wrappers/TAO/tests/Portable_Interceptors/Processing_Mode_Policy/Collocated/PI_ProcMode_Collocated_Tes ACE_wrappers/TAO/tests/Portable_Interceptors/Processing_Mode_Policy/Collocated/PI_ProcMode_Collocated_Test
  fi
else
  echo [`/bin/date`]: Failed to get built tests
  exit 1
fi
#
# run TAO tests
echo [`/bin/date`]: Running tao tests
/usr/bin/perl /home/tao/doc_autobuild/autobuild/autobuild.pl /home/tao/doc_autobuild/autobuild/configs/autobuild/prism/LynxOS42_PPC_GCC322_Standard_Tests.xml
#
# copy test results back to ultra4 so they can be posted to the doc group scoreboard
echo [`/bin/date`]: Copying test results back to rhel4 for posting
if scp LynxOS42_test_results_run_on_rad1.txt rhel4:rad1/doc_scoreboard/lynxos42_ppc_gcc322/standard
then
  rm LynxOS42_test_results_run_on_rad1.txt
  echo [`/bin/date`]: Triggering rhel4 to post the results to the scoreboard
  /usr/local/bin/ssh rhel4 /usr/bin/nohup /home/tao/doc_autobuild/autobuild/configs/autobuild/prism/LynxOS42_PPC_GCC322_Standard_Post.sh
  echo [`/bin/date`]: Back on rad1...
else
  echo [`/bin/date`]: Failed to copy results to rhel4, save for manual posting
  mv LynxOS42_test_results_run_on_rad1.txt LynxOS42_test_results_run_on_rad1_`/bin/date +%y%m%d`.txt
fi
#
echo [`/bin/date`]: Clean up
# Note that we are deliberatly NOT deleting the current ACE_wrappers here, just the previous one(s)
# that were renamed with the last build date postfixed. This means that we can run any built tests
# manually the next day if required.
#
rm -rf ACE_wrappers_*
#
# Save a single "Previous build" for manual testing the next day.
#
if [ -d ACE_wrappers ]; then mv ACE_wrappers ACE_wrappers_`date +%y%m%d`; fi
#
echo [`/bin/date`]: Finished part2 - Rebooting...
/bin/sync
/bin/sleep 1
/bin/sync
/bin/sleep 4
/bin/sync
/bin/reboot -a
exit

# $Id$
#
# At this stage, the TAO tests should have run on rad1 and
# the build.txt file copied back across to /usr/users/tao.
# Simply place the results on the scoreboard. This can't be done
# from rad1 because it can't see the scoreboard.
#
cd /home/tao/rad1/doc_scoreboard/lynxos42_ppc_gcc322/standard
#
echo [`/bin/date`]: Posting test results to the scoreboard
/usr/bin/perl /home/tao/doc_autobuild/autobuild/autobuild.pl /home/tao/doc_autobuild/autobuild/configs/autobuild/prism/LynxOS4_PPC_GCC322_Standard_Post.xml
#
echo [`/bin/date`]: Finished posting results.

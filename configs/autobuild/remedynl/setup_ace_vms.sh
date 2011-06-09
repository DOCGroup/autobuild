#!/bin/sh

rm ace_vms_update.tar
#find ACE_wrappers -name GNUmakefile* -exec rm '{}' ';'
#svn co svn://svn.dre.vanderbilt.edu/DOC/Middleware/sets-anon/ACE+TAO .
svn up
#cd ACE_wrappers
#echo 'ssl=1'>> bin/MakeProjectCreator/config/default.features
#export ACE_ROOT=`pwd`
#export TAO_ROOT=`pwd`/TAO
#perl $ACE_ROOT/bin/mwc.pl -type gnuace -exclude TAO/CIAO 
#cd ..
tar -cf ace_vms_update.tar -g ace_vms_update.tar_inc ACE_wrappers --exclude-vcs

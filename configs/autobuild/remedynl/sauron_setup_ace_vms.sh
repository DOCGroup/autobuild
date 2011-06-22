#!/bin/sh

svn up $HOME/ACE/autobuild
mkdir $HOME/ACE/openvms
cd $HOME/ACE/openvms
rm -rf ace_vms_update.tar
svn co svn://svn.dre.vanderbilt.edu/DOC/Middleware/sets-anon/ACE+TAO .
tar -cf ace_vms_update.tar -g ace_vms_update.tar_inc ACE_wrappers --exclude-vcs
cp ace_vms_update.tar /nfs/openvms/v82ia64
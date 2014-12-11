#!/bin/sh
# when run on a frsh system run the following commands in the $HOME/ace/openvms directory
# git clone git://git.remedy.nl/mpc.git MPC
# git clone git://git.remedy.nl/atcd.git ATCD

cd /nfs/openvms/autobuild
git pull
cd $HOME/ace/autobuild
git pull
cd $HOME/ace/openvms
pushd ATCD && git pull && popd
pushd MPC && git pull && popd
rm -rf ace_vms_update.tar
tar -cf ace_vms_update.tar -g ace_vms_update.tar_inc ATCD MPC --exclude-vcs
cp ace_vms_update.tar /nfs/openvms/v82ia64

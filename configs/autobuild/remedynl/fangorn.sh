#!/bin/sh
#
# $Id$
#

cd $HOME/ACE/autobuild

svn up

sh configs/autobuild/remedynl/fangorn_dds4ccm.sh
sh configs/autobuild/remedynl/fangorn_idl3_plus.sh


#!/bin/sh
#
# $Id$
#

cd $HOME/ACE/autobuild

svn up

sh configs/autobuild/remedynl/fangorn_ccm.sh


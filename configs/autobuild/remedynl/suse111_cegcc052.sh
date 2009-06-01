#!/bin/sh
#
# $Id$
#
cd $HOME/ACE/autobuild

svn up

suse111_cegcc052_cegcc.sh
sh $HOME/ACE/autobuild/configs/autobuild/remedynl/suse111_cegcc052_host.sh
sh $HOME/ACE/autobuild/configs/autobuild/remedynl/suse111_cegcc052d.sh

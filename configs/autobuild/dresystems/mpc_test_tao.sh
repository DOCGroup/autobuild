#!/bin/sh
#
# $Id$
#

PATH=/usr/local/bin:$PATH:$HOME/development/ace/autobuilds/mpc_test_tao/ACE_wrappers/build/mpc_test_tao/bin
export PATH

LD_LIBRARY_PATH=/usr/local/lib:$LD_LIBRARY_PATH
export LD_LIBRARY_PATH

exec /usr/bin/perl $HOME/development/ace/autobuild/autobuild.pl \
                             $HOME/development/ace/autobuild/configs/autobuild/dresystems/mpc_test_tao.xml 2>&1 


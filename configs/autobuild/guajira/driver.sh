#!/bin/sh
#
# $Id$
#

ulimit -d 1048576
ulimit -c 0
umask 022

PATH=.:$HOME/bin:/usr/local/openssh/bin:/pkg/gnu/bin:/pkg/local/bin:/sbin:$PATH
export PATH

exec perl  $HOME/autobuild/autobuild.pl \
    $HOME/autobuild/configs/autobuild/guajira/TRU64_CXX.xml


#!/bin/sh
#
# $Id$
#

PATH=.:$HOME/bin:/usr/local/openssh/bin:/pkg/perl-5.6.1/bin:/pkg/local/bin:/pkg/gnu/bin:/sbin:$PATH
export PATH

exec perl  $HOME/autobuild/autobuild.pl \
    $HOME/autobuild/configs/autobuild/guajira/TRU64_CXX.xml


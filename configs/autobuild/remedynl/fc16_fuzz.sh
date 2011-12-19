#!/bin/sh

cd $HOME/autobuild
svn up

/usr/bin/perl $HOME/autobuild/autobuild.pl \
    $HOME/autobuild/configs/autobuild/remedynl/fc16_fuzz.xml


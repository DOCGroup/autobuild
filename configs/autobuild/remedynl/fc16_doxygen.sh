#!/bin/sh

cd $HOME/ACE/autobuild

svn up

/usr/bin/perl $HOME/ACE/autobuild/autobuild.pl $HOME/ACE/autobuild/configs/autobuild/remedynl/fc16_doxygen.xml


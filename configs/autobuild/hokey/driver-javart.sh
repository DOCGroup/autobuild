#!/bin/sh
#
# $Id$
#
/usr/bin/perl $HOME/autobuild/autobuild.pl \
                             $HOME/autobuild/configs/autobuild/hokey/javart-jvm.xml
/usr/bin/perl $HOME/autobuild/autobuild.pl \
                             $HOME/autobuild/configs/autobuild/hokey/javart-rtsj.xml
/usr/bin/perl $HOME/autobuild/autobuild.pl \
                             $HOME/autobuild/configs/autobuild/hokey/javart-jRate.xml

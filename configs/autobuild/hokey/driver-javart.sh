#!/bin/sh
#
# $Id$
#
exec /usr/bin/perl $HOME/autobuild/autobuild.pl \
                             $HOME/autobuild/configs/autobuild/hokey/javart-jvm.xml
exec /usr/bin/perl $HOME/autobuild/autobuild.pl \
                             $HOME/autobuild/configs/autobuild/hokey/javart-rtsj.xml
exec /usr/bin/perl $HOME/autobuild/autobuild.pl \
                             $HOME/autobuild/configs/autobuild/hokey/javart-jRate.xml

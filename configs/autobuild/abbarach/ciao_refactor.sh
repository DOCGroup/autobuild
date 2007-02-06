#!/bin/sh
#
# $Id$
#
export PATH=/opt/local/bin:$PATH
exec /usr/bin/perl $HOME/autobuild/autobuild.pl \
                             $HOME/autobuild/configs/autobuild/abbarach/ciao_refactor.xml

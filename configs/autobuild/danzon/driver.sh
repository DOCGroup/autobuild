#!/bin/sh
#
# $Id$
#

PATH=/opt/SUNWspro_6.0/SUNWspro/bin:/pkg/perl-5.6.1/bin:$PATH
export PATH

perl -w ../../../autobuild.pl $@


#!/bin/sh
#
# $Id$
#

PATH=/opt/SUNWspro_6.1/SUNWspro/bin:/pkg/perl-5.6.1/bin:$HOME/bin:/usr/ccs/bin:/pkg/gnu2k1/bin:/pkg/gnu/bin:/usr/bin:/project/danzon/pkg/OpenSSH/bin:/pkg/purify/purify-5.1-solaris2:$PATH
export PATH

perl -w ../../../autobuild.pl $@


#!/bin/bash
#
# $Id$
#

PATH=/opt/csw/bin:/opt/SUNWspro/bin:/usr/sfw/sparc-sun-solaris2.10/bin:$PATH
export PATH

# OpenSSL requires an explicit source of entropy on Solaris.  The
# Entropy Gathering Daemon perl script fulfills that requirement.

exec $HOME/autobuild/autobuild.pl \
     $HOME/autobuild/configs/autobuild/sparc/CIDLC.xml 2>&1

#!/bin/bash
#
# $Id$
#

PATH=/opt/csw/gcc3/bin:/opt/csw/bin:/opt/SUNWspro/bin:$PATH
export PATH

# OpenSSL requires an explicit source of entropy on Solaris.  The
# Entropy Gathering Daemon perl script fulfills that requirement.

exec $HOME/autobuild/autobuild.pl \
     $HOME/autobuild/configs/autobuild/corona/SunOS10_x86_GCC34.xml 2>&1 

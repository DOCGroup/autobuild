#!/bin/bash
#
# $Id$
#

PATH=/opt/csw/bin:/opt/SUNWspro/bin:$PATH
export PATH

# OpenSSL requires an explicit source of entropy on Solaris.  The
# Entropy Gathering Daemon perl script fulfills that requirement.

exec $HOME/autobuild/autobuild.pl \
     $HOME/autobuild/configs/autobuild/corona/SunOS9_Sun_Studio9.xml 2>&1 


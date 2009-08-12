#!/bin/bash
#
# $Id$
#

PATH=/opt/csw/bin:/opt/SUNWspro/bin:$PATH
export PATH

# OpenSSL requires an explicit source of entropy on Solaris.  The
# Entropy Gathering Daemon perl script fulfills that requirement.

sh $HOME/autobuild/configs/autobuild/sparc/driver_gcc402.sh
sh $HOME/autobuild/configs/autobuild/sparc/driver_studio.sh


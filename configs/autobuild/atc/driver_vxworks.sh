#!/bin/bash
#
# $Id$
#

ATCROOT=/space
#PATH=/opt/csw/gcc3/bin:/opt/csw/bin:/opt/SUNWspro/bin:$PATH
#export PATH


exec $ATCROOT/autobuild/autobuild.pl \
     $ATCROOT/autobuild/configs/autobuild/atc/VxWorks.xml 2>&1 

#!/bin/sh
#
# $Id$
#

PATH=/usr/local/bin:$PATH
export PATH

exec /usr/bin/perl $HOME/autobuild/autobuild.pl \
                             $HOME/autobuild/configs/autobuild/beguine/Redhat_7.1_No_AMI_Messaging.xml 2>&1 


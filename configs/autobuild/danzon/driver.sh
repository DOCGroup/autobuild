#!/pkg/gnu/bin/bash
#
# $Id$
#

PATH=/export/project/studio8/SUNWspro/bin:/pkg/perl-5.6.1/bin:/pkg/gnu2k1/bin:/pkg/gnu/bin:$PATH
export PATH

# OpenSSL requires an explicit source of entropy on Solaris.  The
# Entropy Gathering Daemon perl script fulfills that requirement.
ENTROPY_FILE=/tmp/entropy
test -f $ENTROPY_FILE || /project/doc/pkg/perl5/bin/egd.pl $ENTROPY_FILE

# ACE_SSL recognizes the "SSL_EGD_FILE" environment variable.
SSL_EGD_FILE=$ENTROPY_FILE
export SSL_EGD_FILE

exec /pkg/perl-5.6.1/bin/perl $HOME/autobuild/autobuild.pl \
                             $HOME/autobuild/configs/autobuild/danzon/SunOS_SunCC55.xml 2>&1 


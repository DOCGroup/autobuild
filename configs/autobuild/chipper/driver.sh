#!/pkg/gnu/bin/bash
#
# $Id$
#

PATH=/opt/SUNWspro_6.1/SUNWspro/bin:/pkg/perl-5.6.1/bin:$HOME/bin:/usr/ccs/bin:/pkg/gnu2k1/bin:/pkg/gnu/bin:/usr/bin:/project/danzon/pkg/OpenSSH/bin:/pkg/purify/purify-5.1-solaris2:$PATH
export PATH

exec /pkg/perl-5.6.1/bin/perl  $HOME/autobuild/autobuild.pl \
    $HOME/autobuild/configs/autobuild/chipper/SOLARIS8_FORTE_UPDATE1.xml


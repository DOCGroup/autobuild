#!/bin/sh
#
# $Id$
#

exec /usr/bin/perl $HOME/autobuild/autobuild.pl \
                             $HOME/autobuild/configs/autobuild/ace_isis/FC12_Minimum.xml

exec /usr/bin/perl $HOME/autobuild/autobuild.pl \
                   $HOME/autobuild/configs/autobuild/ace_isis/FC12_NoInline.xml

exec /usr/bin/perl $HOME/autobuild/autobuild.pl \
  $HOME/autobuild/configs/autobuild/ace_isis/FC12_Static_Core.xml

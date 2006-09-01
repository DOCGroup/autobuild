#!/bin/sh
#
# $Id$
#

exec /usr/bin/perl $HOME/autobuild/autobuild.pl \
                            $HOME/autobuild/configs/autobuild/balar_isis/ImplicitTemplates.xml

exec /usr/bin/perl $HOME/autobuild/autobuild.pl \
                             $HOME/autobuild/configs/autobuild/balar_isis/DynamicHash.xml

exec /usr/bin/perl $HOME/autobuild/autobuild.pl \
                        $HOME/autobuild/configs/autobuild/balar_isis/IPV6.xml

exec /usr/bin/perl $HOME/autobuild/autobuild.pl \
                        $HOME/autobuild/configs/autobuild/balar_isis/Static.xml

exec /usr/bin/perl $HOME/autobuild/autobuild.pl \
                            $HOME/autobuild/configs/autobuild/balar_isis/wchar.xml


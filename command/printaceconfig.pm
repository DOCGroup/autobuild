#
# $Id$
#

package PrintACEConfig;

use strict;
use warnings;

use Cwd;
use FileHandle;
use File::Path;

###############################################################################
# Constructor

sub new
{
    my $proto = shift;
    my $class = ref ($proto) || $proto;
    my $self = {};

    bless ($self, $class);
    return $self;
}

##############################################################################

sub CheckRequirements ()
{
    my $self = shift;
    my $root = main::GetVariable ('root');

    if (!defined $root) {
        print STDERR __FILE__, ": Requires \"root\" variable\n";
        return 0;
    }

    return 1;
}

##############################################################################

sub Run ($)
{
    my $self = shift;
    my $options = shift;
    my $root = main::GetVariable ('root');
    my $project_root = main::GetVariable ('project_root');
    my $config_file = main::GetVariable ('CVS_CONFIG_FILE');
    my %changelogs = ('AUTOBUILD' => 'ChangeLog',
                      'MPC'       => 'ChangeLog',
                      'ACE'       => 'ChangeLog',
                      'TAO'       => 'ChangeLog',
                      'CIAO'      => 'ChangeLog',
                      'DDS'       => 'ChangeLog',
                     );
    my $defurl = 'http://cvs.doc.wustl.edu/viewcvs.cgi/*checkout*';
    my %urls = ('XML_URL'       => "$defurl/<file>?cvsroot=autobuild",
                'AUTOBUILD_URL' => "$defurl/<file>?cvsroot=autobuild",
                'MPC_URL'       => "$defurl/<file>?cvsroot=MPC",
                'ACE_URL'       => "$defurl/<file>",
                'TAO_URL'       => "$defurl/TAO/<file>",
                'CIAO_URL'      => "$defurl/TAO/CIAO/<file>",
                'DDS_URL'       => "$defurl/<file>?cvsroot=DDS",
               );

    # replace all '\x22' with '"'
    $options =~ s/\\x22/"/g;

    foreach my $option (split(/\s+/, $options)) {
      if ($option =~ /([^=]+)=(.*)/) {
        my($name)  = uc($1);
        my($value) = $2;
        ## First, check for a ChangeLog setting
        if (defined $changelogs{$name}) {
          $changelogs{$name} = $value;
        }
        ## Next, check for a URL setting
        elsif (defined $urls{$name}) {
          $value .= '/<file>' if ($value !~ /\/<file>/);
          $urls{$name} = $value;
        }
        ## We did not recognize this setting
        else {
          print "WARNING: $name not recognized.\n";
        }
      }
    }

    if (!defined $project_root) {
        $project_root = 'ACE_wrappers';
    }

    if (!-r $project_root || !-d $project_root) {
        mkpath($project_root);
    }

    if (!-r $root || !-d $root) {
        mkpath($root);
    }

    # chop off trailing slash
    if ($root =~ m/^(.*)\/$/) {
        $root = $1;
    }

    my $url = undef;
    main::PrintStatus ('Config', 'PrintACEConfig');

    $url = $urls{XML_URL};
    $url =~ s/<file>/$config_file/;
    print "XML Config file: <a href=\"$url\">${config_file}</a>\n";

    $url = $urls{AUTOBUILD_URL};
    $url =~ s/<file>/$changelogs{AUTOBUILD}/;
    print "================ <a href=\"$url\">Autobuild $changelogs{AUTOBUILD}</a> ================\n";

    my $current_dir = getcwd ();

    if (!chdir $root) {
          print STDERR __FILE__, ": Cannot change to $root or $ENV{'ROOT'}\n";
          return 0;
    }

    if (!chdir $ENV{'ACE_ROOT'} )
    {
        if (!chdir $project_root) {
            print STDERR __FILE__, ": Cannot change to $project_root or $ENV{'ACE_ROOT'}\n";
            return 0;
        }
    }

    #
    # last ACE Changelog Entry
    #

    if (-r $changelogs{ACE}) {
        $url = $urls{ACE_URL};
        $url =~ s/<file>/$changelogs{ACE}/;
        print "================ <a href=\"$url\">ACE $changelogs{ACE}</a> ================\n";
        print_file ($changelogs{ACE}, 0);
    }

    #
    # last TAO Changelog Entry
    #

    if (-r "TAO/$changelogs{TAO}") {
        $url = $urls{TAO_URL};
        $url =~ s/<file>/$changelogs{TAO}/;
        print "================ <a href=\"$url\">TAO $changelogs{TAO}</a> ================\n";
        print_file ("TAO/$changelogs{TAO}", 0);
    }

    #
    # last CIAO Changelog Entry
    #

    if (-r "TAO/CIAO/$changelogs{CIAO}") {
        $url = $urls{CIAO_URL};
        $url =~ s/<file>/$changelogs{CIAO}/;
        print "================ <a href=\"$url\">CIAO $changelogs{CIAO}</a> ================\n";
        print_file ("TAO/CIAO/$changelogs{CIAO}", 0);
    }

    #
    # last MPC Changelog Entry
    #

    # Look if MPC_ROOT is set, if this is set, then we take MPC_ROOT, else we take MPC/ChangeLog
    my($mpcroot) = $ENV{MPC_ROOT};
    my($mpcpath) = (defined $mpcroot ? $mpcroot : 'MPC');

    if (-r "$mpcpath/$changelogs{MPC}") {
        $url = $urls{MPC_URL};
        $url =~ s/<file>/$changelogs{MPC}/;
        print "================ <a href=\"$url\">MPC $changelogs{MPC}</a> ================\n";
        print_file ("$mpcpath/$changelogs{MPC}", 0);
    }

    #
    # last DDS Changelog Entry
    #

    # Look if DDS_ROOT is set, if this is set, then we take DDS_ROOT, else we take TAO/DDS/ChangeLog
    my($ddsroot) = $ENV{DDS_ROOT};
    my($ddspath) = (defined $ddsroot ? $ddsroot : 'TAO/DDS');

    if (-r "$ddspath/$changelogs{DDS}") {
        $url = $urls{DDS_URL};
        $url =~ s/<file>/$changelogs{DDS}/;
        print "================ <a href=\"$url\">DDS $changelogs{DDS}</a> ================\n";
        print_file ("$ddspath/$changelogs{DDS}", 0);
    }

    #
    # config.h, if it exists
    #

    if (-r "ace/config.h") {
        print "================ config.h ================\n";
        print_file ("ace/config.h", 1);
    }

    #
    # default.features, if it exists
    #

    if (-r "bin/MakeProjectCreator/config/default.features") {
        print "================ default.features ================\n";
        print_file ("bin/MakeProjectCreator/config/default.features", 1);
    }

    #
    # platform_macros.GNU, if it exists
    #

    if (-r "include/makeinclude/platform_macros.GNU") {
        print "================ platform_macros.GNU ================\n";
        print_file ("include/makeinclude/platform_macros.GNU", 1);
    }

    if ( -r "VERSION" ) {
        print "================ ACE VERSION ================\n";

        print_file ("VERSION", 0);
    }

    if ( -r "TAO/VERSION" ) {
        print "================ TAO VERSION ================\n";

        print_file ("TAO/VERSION", 0);
    }

    if ( -r "TAO/CIAO/VERSION" ) {
        print "================ CIAO VERSION ================\n";

        print_file ("TAO/CIAO/VERSION", 0);
    }

    if ( -r "TAO/DDS/VERSION" ) {
        print "================ DDS VERSION ================\n";

        print_file ("TAO/DDS/VERSION", 0);
    }

    chdir $current_dir;

    return 1;
}

##############################################################################

sub print_file ($$)
{
    my $filename = shift;
    my $printall = shift;

    my $filehandle = new FileHandle ($filename, "r");

    while (<$filehandle>) {
        print $_;

        last if ($printall == 0);
    }
}

##############################################################################

main::RegisterCommand ("print_ace_config", new PrintACEConfig ());

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

    # replace all '\x22' with '"'
    $options =~ s/\\x22/"/g;

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

    main::PrintStatus ('Config', 'PrintACEConfig');

    print "XML Config file: <a href=\"http://cvs.doc.wustl.edu/viewcvs.cgi/*checkout*/${config_file}/?cvsroot=autobuild\">${config_file}</a>\n";

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

    if (-r "ChangeLog") {
        print "================ <a href=\"http://cvs.doc.wustl.edu/viewcvs.cgi/*checkout*/ChangeLog\">ACE ChangeLog</a> ================\n";
        print_file ("ChangeLog", 0);
    }

    #
    # last TAO Changelog Entry
    #

    if (-r "TAO/ChangeLog") {
        print "================ <a href=\"http://cvs.doc.wustl.edu/viewcvs.cgi/*checkout*/TAO/ChangeLog\">TAO ChangeLog</a> ================\n";
        print_file ("TAO/ChangeLog", 0);
    }

    #
    # last CIAO Changelog Entry
    #

    if (-r "TAO/CIAO/ChangeLog") {
        print "================ <a href=\"http://cvs.doc.wustl.edu/viewcvs.cgi/*checkout*/TAO/CIAO/ChangeLog\">CIAO ChangeLog</a> ================\n";
        print_file ("TAO/CIAO/ChangeLog", 0);
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

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

    my $project_root = main::GetVariable ('project_root');

    if (!defined $project_root) {
        print STDERR __FILE__, ": Requires \"project_root\" variable\n";
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

    my $current_dir = getcwd ();

    if (!chdir $root) {
          print STDERR __FILE__, ": Cannot change to $root or $ENV{'ROOT'}\n";
          return 0;
    }

    if (!chdir $ENV{'ACE_ROOT'} ) 
    {
        if (!defined $project_root) {
            $project_root = 'ACE_wrappers';
        }
    
        if (!chdir $project_root) {
            print STDERR __FILE__, ": Cannot change to $project_root or $ENV{'ACE_ROOT'}\n";
            return 0;
        }
    }

    #
    # last ACE Changelog Entry
    #

    if (-r "ChangeLog") {
        print "================ ACE ChangeLog ================\n";
        print_file ("ChangeLog", 0);
    }

    #
    # last TAO Changelog Entry
    #

    if (-r "TAO/ChangeLog") {
        print "================ TAO ChangeLog ================\n";
        print_file ("TAO/ChangeLog", 0);
    }

    #
    # config.h, if it exists
    #

    if (-r "ace/config.h") {
        print "================ config.h ================\n";
        print_file ("ace/config.h", 1);
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

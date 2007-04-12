#
# $Id$
#

package SVN;

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

    if (!-r $root || !-d $root) {
        mkpath($root);
    }

    # chop off trailing slash
    if ($root =~ m/^(.*)\/$/) {
        $root = $1;
    }

    main::PrintStatus ('Setup', 'SVN');

    my $current_dir = getcwd ();

    if (!chdir $root) {
        print STDERR __FILE__, ": Cannot change to $root\n";
        return 0;
    }

    # If dir= is given, extract the dir name, then remove the option from
    # the options string. If no dir is given, just run the command with
    # specified options in $root.
    my $dir;
    if ($options =~ m/dir=([^\s]*)/) {
        $dir = $1;
        $options =~ s/dir=$dir//;
    }
    else {
        $dir = $root;
    }

    if (!chdir $dir) {
        mkpath($dir);
        if(!chdir $dir) {
            print STDERR __FILE__, ": Cannot change to $dir\n";
            return 0;
        }
    }

    my $svn_program = main::GetVariable ('svn_program');
    if (! defined $svn_program) {
        # The "svn_program" variable was not defined in the
        # XML config file.  Default to using a program called "svn".
        $svn_program = "svn";
    }

    ## We should only perform a cleanup and status below if there
    ## is already an svn checkout in the current directory.
    my $cleanup_and_status =
         ((defined $ENV{SVN_ASP_DOT_NET_HACK} && -d '_svn') || -d '.svn');

    system ("$svn_program cleanup") if ($cleanup_and_status);
    my $ret = system ("$svn_program $options");
    if ($ret != 0) {
        print STDERR __FILE__, " ERROR: $svn_program $options returned $ret\n";
    }
    system ("$svn_program status") if ($cleanup_and_status);

    chdir $current_dir;

    return 1;
}

##############################################################################

main::RegisterCommand ("svn", new SVN ());

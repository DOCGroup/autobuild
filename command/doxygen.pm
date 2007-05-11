#
# $Id$
#

package doxygen;

use strict;
use warnings;
use Cwd;
use File::Copy;
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
sub CheckRequirements
{
    if (!defined $ENV{ACE_ROOT}) {
        print STDERR __FILE__, ": Requires \"ACE_ROOT\" environment variable\n";
        return 0;
    }

    return 1;
}

##############################################################################
sub Run
{
    my $self = shift;
    my $options = shift;

    main::PrintStatus ('Compile', 'doxygen');

    my $current_dir = getcwd ();
    my $dir;
    if ($options =~ s/dir='([^']*)'//) { #'{
        $dir = $1;
    } elsif ($options =~ s/dir=([^\s]*)//) {
        $dir = $1;
    }

    my $root = main::GetVariable ('root');
    my $project_root = main::GetVariable ('project_root');
    if (!chdir $root) {
        print STDERR __FILE__, ": Cannot change to $root\n";
        return 0;
    }
    if (!defined $project_root) {
        $project_root = 'ACE_wrappers';
    }
    if (!-r $project_root || !-d $project_root) {
        mkpath($project_root);
    }
    if (!chdir $project_root) {
        print STDERR __FILE__, ": Cannot change to $project_root\n";
    }
    if( defined $dir )
    {
        if(!chdir $dir) {
          print STDERR __FILE__, ": Cannot change to $dir\n";
          return 1;
        }
    }
    print "Dir is " . getcwd() . "\n";

    my $dont_generate = 0;
    my $dont_install = 0;
    my $DEST;
    my $ACE_ROOT = $ENV{ACE_ROOT};

    if ($options =~ s/dest=([^\s]*)//) {
       $DEST = $1;
    } else {
        print 'ERROR: dest=<destination_path> must be provided to the doxygen'.
            ' autobuild command.\n';
        return 1;
    }

    if (!open(GENDOXY,
              "perl $ACE_ROOT/bin/generate_doxygen.pl -verbose " .
              "-html_output $DEST 2>&1 |")) {
        print "ERROR: Cannot start doxygen generation script\n";
        return 1;
    }
    while (<GENDOXY>) {
        print;
    }
    close(GENDOXY);

    chdir $current_dir;

    return 1;
}

##############################################################################

main::RegisterCommand ("doxygen", new doxygen ());

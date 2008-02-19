#
# $Id$
#

package vmsMake;

use strict;
use warnings;

use Cwd;
use File::Path;
use File::Temp qw/ tempfile  /;

require VMS::Filespec;
import VMS::Filespec qw(unixpath);

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

    if (!-r $root || !-d $root) {
        mkpath($root);
    }

    # chop off trailing slash
    if ($root =~ m/^(.*)\/$/) {
        $root = $1;
    }

    main::PrintStatus ('Compile', 'make');

    my $current_dir = getcwd ();
    
    my $dir;
 
    if ($options =~ m/dir='([^']*)'/) {
        $dir = $1;
        $options =~ s/dir='$dir'//;
    }
    elsif ($options =~ m/dir=([^\s]*)/) {
        $dir = $1;
        $options =~ s/dir=$dir//;
    }

    # setup a temporary initializationfile for bash environment
    my $rcfh;
    my $rctemp;
    ($rcfh, $rctemp) = tempfile ("rctmpXXXXX", DIR => $root, UNLINK => 1);
    foreach my $envvar (main::GetEnvironment ()) {
      if ($envvar->{NAME} eq 'PATH') {
        print $rcfh "export PATH=\$PATH:" . $ENV{$envvar->{NAME}} . "\n";
      }
      else {
        print $rcfh "export ". $envvar->{NAME} . "=" . $ENV{$envvar->{NAME}} . "\n";
      }
    }
    close ($rcfh);

    my $make_program = "bash --rcfile " . unixpath($rctemp) . " -c \"make ";

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
          return 0; 
        }
    }

    my $command;
    my $pattern;
    my $ret;
 
    if ($options =~ m/find=([^\s]*)/) {
        $pattern = $1;
        $options =~ s/find=$pattern//;
        print "Pattern: $pattern\n";
        my @makes = glob $pattern;
        my $makefile;
        $options =~ s/'/"/g;
        foreach $makefile (@makes) {
            $command = "$make_program -f $makefile $options\"";
            print "Running: $command\n";
            $ret = system ($command);
        }
    }
    else {
        $options =~ s/'/"/g;
        $command = "$make_program -f GNUmakefile $options\"";
        print "Running: $command\n";
        $ret = system ($command);
    }

    if( $ret != 0  )
    {
        my $working_dir = getcwd();

        ## If we used 'make -C' to change the directory, let's
        ## append that information to the working_dir, so that we generate
        ## a more accurate error message.
        if( $command =~ /\-C\s+([\w\/]+)/  )
        {
            $working_dir = "$working_dir/$1"; 
        }

        print "[BUILD ERROR detected in $working_dir]\n ";
    } 

    chdir $current_dir;

    return 1;
}

##############################################################################

main::RegisterCommand ("make", new vmsMake ());

#
# $Id$
#

package Make;

use strict;
use warnings;

use Cwd;
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

    # replace all '\x22' with '"'
    $options =~ s/\\x22/"/g;

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

    if ($options =~ s/dir='([^']*)'//) {
        $dir = $1;
    }
    elsif ($options =~ s/dir=([^\s]*)//) {
        $dir = $1;
    }

    my($conditional) = undef;
    my($cond_unlink) = undef;
    if ($options =~ s/conditional(_rm)?='([^']*)'//) {
      $cond_unlink = $1;
      $conditional = $2;
    }
    elsif ($options =~ s/conditional(_rm)?=([^\s]*)//) {
      $cond_unlink = $1;
      $conditional = $2;
    }

    ## If a conditional file was supplied...
    if (defined $conditional) {
      if (-e $conditional) {
        ## Should we remove the file...
        if ($cond_unlink) {
          ## Just remove the file and continue on
          unlink($conditional);
        }
      }
      else {
        ## The file does not exist, so we must not run the make command
        return 1;
      }
    }

    my $make_program = main::GetVariable ('make_program');
    if (! defined $make_program) {
        # The "make_program" variable was not defined in the
        # XML config file.  Default to using a program called "make".
        $make_program = "make"
    }

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
        return 0;
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
    my $ret = 0;

    if ($options =~ s/find=([^\s]*)//) {
        $pattern = $1;
        print "Pattern: $pattern\n";
        my @makes = glob $pattern;
        my $makefile;
        $options =~ s/'/"/g;
        foreach $makefile (@makes) {
            $command = "$make_program -f $makefile $options";
            print "Running: $command\n";
            $ret = system ($command);
        }
    }
    else {
        $options =~ s/'/"/g;
        $command = "$make_program $options";
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

main::RegisterCommand ("make", new Make ());

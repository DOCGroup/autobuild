#
# $Id$
#

package Create_File;

use strict;
use FileHandle;
use Cwd;

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
    if (!-r $root) {
        print STDERR __FILE__, ": Cannot read root dir: $root\n";
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

    # chop off trailing slash
    if ($root =~ m/^(.*)\/$/) {
        $root = $1;
    }

    print "\n#################### Setup (Creating configuration files)\n\n";

    # Grab the filename and the output
    
    my $filename;
    my $output;
    
    if ($options =~ m/file='(.*?)'/) {
        $filename = $1;
    }
    elsif ($options =~ m/file=([^\s]*)/) {
        $filename = $1;
    }
    else {
        print STDERR __FILE__, ": No file specified in command options\n";
        return 0;
    }
    
    if ($options =~ m/output='(.*?)'/) {
        $output = $1;
    }

    $output =~ s/\\n/\n/g;
    $output =~ s/\\x22/"/g;
    $output =~ s/\\x27/'/g;

    my $file_handle = new FileHandle ($root . '/' . $filename, "w");

    print $file_handle $output;


    return 1;
}

##############################################################################

main::RegisterCommand ("create_file", new Create_File ());

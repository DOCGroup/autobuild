#
# $Id$
#

package File_Manipulation;

use strict;
use warnings;

use Cwd;
use File::Find;
use File::Path;

sub create ($);
sub sam ($);
sub clean ($);

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

    # replace all '\x22' with '"'
    $options =~ s/\\x22/"/g;

    if (!-r $root || !-d $root) {
        mkpath($root);
    }

    # chop off trailing slash
    if ($root =~ m/^(.*)\/$/) {
        $root = $1;
    }

    if ($main::verbose == 1) {
        main::PrintStatus ('Setup', 'File_Manipulation');
    }

    my $current_dir = getcwd ();

    if (!chdir $root) {
        print STDERR __FILE__, ": Cannot change to $root\n";
        return 0;
    }

    # Collect the options
    
    my $type;
    my $filename;
    my $output;
    
    if ($options =~ m/type='([^"]*)'/) {
        $type = $1;
    }
    elsif ($options =~ m/type=([^\s]*)/) {
        $type = $1;
    }
    else {
        print STDERR __FILE__, ": No type specified in command options\n";
        return 0;
    }
    
    if ($options =~ m/file='([^"]*)'/) {
        $filename = $1;
    }
    elsif ($options =~ m/file=([^\s]*)/) {
        $filename = $1;
    }
    else {
        print STDERR __FILE__, ": No file specified in command options\n";
        return 0;
    }

    if ($options =~ m/output='([^"]*)'/) {
        $output = $1;
    }

    # Act on the type
    if ($type eq "append") {
        if (!defined $output) {
            print STDERR __FILE__, ": No output specified for \"append\" type\n"; 
            return 0;
        }

        if (-e $filename) {
            # Expand some codes
            $output =~ s/\\n/\n/g;
            $output =~ s/\\x22/"/g;
            $output =~ s/\\x27/'/g;

            my $file_handle = new FileHandle ($root . '/' . $filename, 'a');

            if (!defined $file_handle) {
                print STDERR __FILE__, ": Error opening file ($root/$filename): $!\n";
                return 0;
            }

            print $file_handle $output;
        }
        else {
            print STDERR __FILE__, ": \"$filename\" does not exist!\n";
            return 0;
        }
    } elsif ($type eq "create") {

        if (!defined $output) {
            print STDERR __FILE__, ": No output specified for \"create\" type\n";
            return 0;
        }
        
        # Expand some codes
        
        $output =~ s/\\n/\n/g;
        $output =~ s/\\x22/"/g;
        $output =~ s/\\x27/'/g;
        
        my $file_handle = new FileHandle ($root . '/' . $filename, 'w');

        if (!defined $file_handle) {
            print STDERR __FILE__, ": Error creating file ($root/$filename): $!\n";
            return 0;
        }

        print $file_handle $output;
    }
    elsif ($type eq "delete") {
        
        unlink $filename;
    }
    elsif ($type eq "mustnotexist") {
        
        if (-e $filename) {
            print STDERR "\"$root/$filename\" exists!\n";
            return 0;
        }
    }
    else {
        print STDERR __FILE__, ": Unrecognized type \"$type\"\n";
        return 0;
    }

    chdir $current_dir;

    return 1;
}

##############################################################################

main::RegisterCommand ("file_manipulation", new File_Manipulation ());

#
# $Id$
#

package File_Manipulation;

use strict;
use warnings;

use Cwd;
use File::Find;
use File::Path;
use File::Compare;
use File::Copy;

sub create ($);
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

    # replace all '\x22' with '"'
    $options =~ s/\\x22/"/g;

    my $root = main::GetVariable ('root');

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
    my $target;

    if ($options =~ m/type='([^']*)'/) {
        $type = $1;
    }
    elsif ($options =~ m/type=([^\s]*)/) {
        $type = $1;
    }
    else {
        print STDERR __FILE__, ": No type specified in command options\n";
        return 0;
    }

    if ($options =~ m/file='([^']*)'/) {
        $filename = $1;
    }
    elsif ($options =~ m/file=([^\s]*)/) {
        $filename = $1;
    }
    else {
        print STDERR __FILE__, ": No file specified in command options\n";
        return 0;
    }

    if ($options =~ m/output='([^']*)'/) {
        $output = $1;
    }

    if ($options =~ m/target='([^']*)'/) {
      $target = $1;
    }
    elsif ($options =~ m/target=([^\s]*)/) {
      $target = $1;
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
        $output =~ s/\\x27/'/g;

        my $file_handle = new FileHandle ($root . '/' . $filename, 'w');

        if (!defined $file_handle) {
            print STDERR __FILE__, ": Error creating file ($root/$filename): $!\n";
            return 0;
        }

        print $file_handle $output;
    }
    elsif ($type eq "update") {

        if (!defined $output) {
            print STDERR __FILE__, ": No output specified for \"update\" type\n";
            return 0;
        }

        # Expand some codes

        $output =~ s/\\n/\n/g;
        $output =~ s/\\x27/'/g;

        my $full_path = $root . '/' . $filename;
        my $tmp_path  = $full_path . ".$$";
        my $file_handle = new FileHandle ($tmp_path, 'w');

        if (!defined $file_handle) {
            print STDERR __FILE__, ": Error creating file ($tmp_path): $!\n";
            return 0;
        }

        print $file_handle $output;
        close($file_handle);

        my $different = 1;
        if (-r $full_path &&
            -s $tmp_path == -s $full_path &&
            compare($tmp_path, $full_path) == 0) {
          $different = 0;
        }

        if ($different) {
          unlink($full_path);
          if (!rename($tmp_path, $full_path)) {
            print STDERR __FILE__, ": Error renaming $tmp_path to $full_path: $!\n";
            return 0;
          }
        }
        else {
          unlink($tmp_path);
        }
    }
    elsif ($type eq "delete") {

        unlink $filename;
    }
    elsif ($type eq "rmtree") {

        rmtree ($filename, 0, 1);
    }
    elsif ($type eq "mustnotexist") {

        if (-e $filename) {
            print STDERR "\"$root/$filename\" exists!\n";
            return 0;
        }
    }
    elsif ($type eq "copy") {

        if (!defined $target) {
            print STDERR __FILE__, ": No target specified for \"copy\" type\n";
            return 0;
        }

        my $src_file_name = $root . '/' . $filename;
        my $target_file_name = $root . '/' . $target;
        my $result = copy($src_file_name, $target_file_name);

        if ($result == 0) {
          print STDERR __FILE__, ": Error copying file ($src_file_name to $target_file_name";
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

#
# $Id$
#

package Create_Config;

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
        print STDERR "make: Requires \"root\" variable\n";
        return 0;
    }
    if (!-r $root) {
        print STDERR "make: Cannot read root dir: $root\n";
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

    print "\n#################### Creating configuration files\n\n";

    my $current_dir = getcwd ();

    if (!chdir $root) {
        print STDERR "make.pm: Cannot change to $root\n";
        return 0;
    }

    # By default we generate the ACE configuration file.
    my $output = 'ace/config.h';
    my $contents = '';
    # Remove any leading blanks...
    $options =~ s/^\s+//;
    do {
      if ($options =~ m/^output\(([^\s]*)\)/) {
        $output = $1;
        $options =~ s/^output\([^\)]+\)//;
      } elsif ($options =~ m/^undefine\(([^\)]+)\)/) {
        $contents .= "#ifdef ".$1."\n";
        $contents .= "#undef ".$1."\n";
        $contents .= "#endif /* ".$1." */\n";
        $options =~ s/^undefine\([^\)]+\)//;
      } elsif ($options =~ m/^define\(([^\)]+)\)/) {
        $contents .= "#define ".$1."\n";
        $options =~ s/^define\([^\)]+\)//;
      } elsif ($options =~ m/^include\(([^\)]+)\)/) {
        $contents .= "#include \"".$1."\"\n";
        $options =~ s/^include\([^\)]+\)//;
      } elsif ($options =~ m/^makeinclude\(([^\)]+)\)/) {
        $contents .= "include \$(ACE_ROOT)/include/makeinclude/".$1."\n";
        $options =~ s/^makeinclude\([^\)]+\)//;
      } elsif ($options =~ m/^makemacro\(([^\)]+)\)/) {
        $contents .= $1."\n";
        $options =~ s/^makemacro\([^\)]+\)//;
      } else {
        print STDERR "Malformed options <$options>\n";
        return 0;
      }
      # Remove any leading blanks...
      $options =~ s/^\s+//;
    } while ($options ne '');

    $contents =~ s/\{/(/g;
    $contents =~ s/\}/)/g;

    my $file_handle = new FileHandle ($output, "w");
    print $file_handle $contents;

    return 1;
}

##############################################################################

main::RegisterCommand ("create_config", new Create_Config ());

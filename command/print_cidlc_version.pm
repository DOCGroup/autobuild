#
# $Id$
#

package print_cidlc_version;

use strict;
use warnings;

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

    my $cidlc_program = "TAO/CIAO/bin/cidlc";

    main::PrintStatus ('Config', "print cidlc version" );

    print "<h3>cidlc version (";
    print $cidlc_program;
    print " --version)</h3>\n";

    my $command = "$cidlc_program --version";

    system($command);

    chdir $current_dir;

    return 1;
}

##############################################################################

main::RegisterCommand ("print_cidlc_version", new print_cidlc_version());

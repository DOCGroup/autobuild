#

package Shell;

use strict;
use warnings;

use Cwd;
use FileHandle;
use File::Path;

use common::utility;

###############################################################################
# Constructor

sub new
{
    my $proto = shift;
    my $class = ref ($proto) || $proto;
    my $self = {'substitute_vars_in_options' => 1};

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

    main::PrintStatus ('Setup', 'Shell');

    my $cd = ChangeDir->new({dir => $root});
    return {'failure' => 'fatal'} unless ($cd);

    print "Running: ${options}\n";

    my $result = {};
    utility::run_command ($options, $result);

    return $result;
}

##############################################################################

main::RegisterCommand ("shell", new Shell ());

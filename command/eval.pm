#

package Eval;

use strict;
use warnings;

use FileHandle;
use File::Path;

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

    return 1;
}

##############################################################################

sub Run ($)
{
    my $self = shift;
    my $options = shift;

    main::PrintStatus ('Setup', 'eval');

    print "Running eval: ${options}\n";

    my $fh = new FileHandle();
    if (open($fh, "${options} |")) {
        while (<$fh>) {
            if (/(\w+)=(.*)/) {
                $ENV{$1} = $2
            }
        }
        close ($fh);
    }

    return 1;
}

##############################################################################

main::RegisterCommand ("eval", new Eval ());

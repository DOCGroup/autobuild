#
# $Id$
#

package SAM;

use strict;
use warnings;

use Cwd;
use FileHandle;
use File::Find;

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
    my $sam_root = main::GetVariable ('sam_root');

    if (!defined $root) {
        print STDERR __FILE__, ": Requires \"root\" variable\n";
        return 0;
    }

    if (!-r $root || !-d $root) {
        print STDERR __FILE__, ": Cannot access \"root\" directory: $root\n";
        return 0;
    }

    if (!defined $sam_root) {
        print STDERR __FILE__, ": Requires \"sam_root\" variable\n";
        return 0;
    }

    if (!-r $sam_root || !-d $sam_root) {
        print STDERR __FILE__, ": Cannot access \"sam_root\" directory: $sam_root\n";
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
    my $sam_root = main::GetVariable ('sam_root');

    # chop off trailing slash
    if ($root =~ m/^(.*)\/$/) {
        $root = $1;
    }

    if ($sam_root =~ m/^(.*)\/$/) {
        $sam_root = $1;
    }

    main::PrintStatus ('Compile', 'SAM');

    my $current_dir = getcwd ();

    if (!chdir $root) {
        print STDERR __FILE__, ": Cannot change to $root\n";
        return 0;
    }

    if ($options =~ m/clean/) {
        $self->clean ($sam_root);
    }

    if ($options =~ m/create/) {
        $self->create ($sam_root);
    }

    if ($options =~ m/sam/) {
        $self->sam ($sam_root);
    }

    chdir $current_dir;

    return 1;
}

##############################################################################
my $sam_root;

sub create_wanted
{
    if (-d && m/^CVS$/) {
        if (-r 'Makefile') {
            my $name = $File::Find::name;
            $name =~ s/^.\///;
            $name =~ s/\\/\//g;
            $name =~ s/\/CVS//;
            $name =~ s/\/\//\//;
            print "Running Create_Sam in $name\n";
            system ("perl -w $sam_root/create_sam.pl");
        }
    }
}

sub create ($)
{
    my $self = shift;
    $sam_root = shift;

    find(\&create_wanted, '.');
}

sub sam_wanted
{
    if (-d && m/^CVS$/) {
        if (-r 'Makefile') {
            my $name = $File::Find::name;
            $name =~ s/^.\///;
            $name =~ s/\\/\//g;
            $name =~ s/\/CVS//;
            $name =~ s/\/\//\//;
            print "Running Sam in $name\n";
            system ("perl -w $sam_root/sam.pl");
        }
    }
}

sub sam ($)
{
    my $self = shift;
    $sam_root = shift;

    find(\&sam_wanted, '.');
}

sub clean_wanted
{
    if (-d && m/^CVS$/) {
        if (-r 'Makefile') {
            my $name = $File::Find::name;
            $name =~ s/^.\///;
            $name =~ s/\\/\//g;
            $name =~ s/\/CVS//;
            $name =~ s/\/\//\//;
            print "Cleaning Sam generated files in $name\n";
            unlink <*.dsp>, <*.dsw>, <*.bor>, <*.gnu>, <*.am>, <.*.gnu.depend>, 'GNUmakefile';
        }
    }
}

sub clean ($)
{
    my $self = shift;
    $sam_root = shift;

    find(\&clean_wanted, '.');
}

##############################################################################

main::RegisterCommand ("sam", new SAM ());

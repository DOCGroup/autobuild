#
# $Id$
#

package SAM;

use strict;
use FileHandle;
use Cwd;
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
    if (!-r $root) {
        print STDERR __FILE__, ": Cannot read root dir: $root\n";
        return 0;
    }

    if (!defined $sam_root) {
        print STDERR __FILE__, ": Requires \"sam_root\" variable\n";
        return 0;
    }
    if (!-r $sam_root) {
        print STDERR __FILE__, ": Cannot read sam_root dir: $root\n";
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

    print "\n#################### Compile (SAM) \n\n";

    my $current_dir = getcwd ();

    if (!chdir $root) {
        print STDERR __FILE__, ": Cannot change to $root\n";
        return 0;
    }

    my $output;

    if ($options =~ m/clean/) {
        $output .= $self->clean ($sam_root);
    }

    if ($options =~ m/create/) {
        $output .= $self->create ($sam_root);
    }

    if ($options =~ m/sam/) {
        $output .= $self->sam ($sam_root);
    }

    chdir $current_dir;
    print $output;

    return 1;
}

##############################################################################
my $output;
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
            $output .= "Running Create_Sam in $name\n";
            $output .= `perl -w $sam_root/create_sam.pl 2>&1`;
        }
    }
}

sub create ($)
{
    my $self = shift;
    $sam_root = shift;

    $output = "";

    find(\&create_wanted, '.');

    return $output;
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
            $output .= "Running Sam in $name\n";
            $output .= `perl -w $sam_root/sam.pl 2>&1`;
        }
    }
}

sub sam ($)
{
    my $self = shift;
    $sam_root = shift;

    $output = "";

    find(\&sam_wanted, '.');

    return $output;
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
            $output .= "Cleaning Sam generated files in $name\n";
            unlink <*.dsp>, <*.dsw>, <*.bor>, <*.gnu>, <*.am>, 'GNUMakefile';
        }
    }
}

sub clean ($)
{
    my $self = shift;
    $sam_root = shift;

    $output = "";

    find(\&clean_wanted, '.');

    return $output;
}

##############################################################################

main::RegisterCommand ("sam", new SAM ());

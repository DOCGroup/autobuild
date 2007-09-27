#
# $Id$
#
# Setup_LVRT - Set up a LabVIEW Real Time target. This command copies all
# the DLLs in $ACE_ROOT/lib to the LabVIEW RT target.

package Setup_LVRT;

use strict;
use warnings;

use Cwd;
use FileHandle;
use File::Path;
use Net::FTP;

###############################################################################
# Constructor

sub new
{
    my $proto = shift;
    my $class = ref ($proto) || $proto;
    my $self = {};
    $self->{FTP} = undef;

    bless ($self, $class);
    return $self;
}

sub DESTROY
{
    my $self = shift;
    if (defined $self->{FTP}) {
        $self->{FTP}->close;
    }
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

    if (!defined $ENV{'ACE_RUN_LVRT_TGTHOST'}) {
        print STDERR __FILE__, ": Requires defining target hostname/IP with ",
              "ACE_RUN_LVRT_TGTHOST\n";
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
    my $targethost = $ENV{'ACE_RUN_LVRT_TGTHOST'};

    if (!-r $root || !-d $root) {
        mkpath($root);
    }

    # chop off trailing slash
    if ($root =~ m/^(.*)\/$/) {
        $root = $1;
    }
    if (!defined $project_root) {
        $project_root = 'ACE_wrappers';
    }

    main::PrintStatus ('Setup', 'Setup_LVRT');

    my $current_dir = getcwd ();

    if (!chdir $root) {
        print STDERR __FILE__, ": Cannot change to $root\n";
        return 0;
    }
    if (!chdir $project_root) {
        print STDERR __FILE__, ": Cannot change to $project_root\n";
	chdir $current_dir;
        return 0;
    }
    if (!chdir "lib") {
        print STDERR __FILE__, ": Cannot change to $project_root lib\n";
	chdir $current_dir;
        return 0;
    }

    $self->{FTP} = new Net::FTP ($targethost);
    if (!defined $self->{FTP}) {
        print STDERR "$@\n";
        return 0;
    }
    $self->{FTP}->login("","");
    $self->{FTP}->cwd("/ni-rt");
    $self->{FTP}->binary();

    print "Copying $project_root/lib DLLs to ${targethost}\n";

    opendir(LIBDIR, ".");
    my @dlls = grep { /\.dll$/i } readdir(LIBDIR);
    closedir LIBDIR;
    my $dll;
    foreach $dll (@dlls) {
        print "$dll ...\n";
        $self->{FTP}->put($dll);
    }
    $self->{FTP}->quit();

    chdir $current_dir;

    return 1;
}

##############################################################################

main::RegisterCommand ("setup_lvrt", new Setup_LVRT ());

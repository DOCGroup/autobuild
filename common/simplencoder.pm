# $Id$

package SimpleEncoder;

use strict;
use FileHandle;

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

sub escape_options ($)
{
    my $options = shift;
    my $new_options = $options;

    ($new_options = $options) =~ s/([\"])/\\$1/g;

    return $new_options;
}

###############################################################################
# Methods

sub Encode ($\%)
{
    my $self = shift;
    my $file = shift;
    my $data = shift;

    my $file_handle = new FileHandle ($file, 'w');

    if (!defined $file_handle) {
        print STDERR "Error: Could not open file <$file>: $!\n";
        return 0;
    }

    print $file_handle "<!-- This file was automatically generated.  Any changes made directly to\n     this file will be lost the next time it is generated. -->\n\n";
    print $file_handle "<autobuild>\n";

    if (scalar (@{$data->{ENVIRONMENT}}) != 0 && scalar (keys (%{$data->{VARS}})) != 0) {
        print $file_handle "  <configuration>\n";

        if (scalar (keys (%{$data->{VARS}})) != 0) {
            foreach my $varkey (keys (%{$data->{VARS}})) {
                print $file_handle "    <variable name=\"$varkey\" value=\"$data->{VARS}->{$varkey}\" />\n";
            }
        }

        if (scalar (@{$data->{ENVIRONMENT}}) != 0) {
           print $file_handle "\n" if (scalar (keys (%{$data->{VARS}})));
           foreach my $envvar (@{$data->{ENVIRONMENT}}) {
                my $out_xml = "    <environment name=\"$envvar->{NAME}\"";
                $out_xml .= " value=\"$envvar->{VALUE}\"";
                $out_xml .= " type=\"$envvar->{TYPE}\"" unless ("replace" eq $envvar->{TYPE});
                $out_xml .= " groups=\"" . join(',',@{$envvar->{GROUPS}}) . "\"" unless (!defined $envvar->{GROUPS} || !scalar @{$envvar->{GROUPS}});
                $out_xml .= " />\n";
                print $file_handle $out_xml;
            }
        }

        print $file_handle "  </configuration>\n";

        if (scalar (@{$data->{COMMANDS}}) != 0) {
            print $file_handle "\n";
        }
    }

    foreach my $command (@{$data->{COMMANDS}}) {
        my $comments = "  <!-- $command->{FILE} line $command->{LINE_FROM} -->\n";
        my $out_xml = "  <command name=\"$command->{NAME}\"";
        $out_xml .= " options=\"" . escape_options ($command->{OPTIONS}) . "\"" unless ($command->{OPTIONS} eq "");
        $out_xml .= ($command->{SUBVARS} ? " " : " no") . "SubsVars" unless (!defined $command->{SUBVARS} || 2 == $command->{SUBVARS});
        $out_xml .= " directory=\"$command->{DIRECTORY}\"" unless ($command->{DIRECTORY} eq "");
        $out_xml .= " group=\"$command->{GROUP}\"" unless (!defined $command->{GROUP} || "" eq $command->{GROUP});
        $out_xml .= " if=\"$command->{IF_TEXT}\"" unless ($command->{IF_TEXT} eq "1");
        $out_xml .= " />\n";
        print $file_handle $comments.$out_xml;
    }

    print $file_handle "</autobuild>\n";
    $file_handle->close;

    return 1;
}

1;

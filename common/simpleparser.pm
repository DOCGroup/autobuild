# $Id$

package SimpleParser;

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

###############################################################################
# Methods

sub Parse ($\%)
{
    my $self = shift;
    my $file = shift;
    my $data = shift;

    my $file_handle = new FileHandle ($file, 'r');

    if (!defined $file_handle) {
        print STDERR "Error: Could not open file <$file>: $!\n";
        return 0;
    }

    my $state = 'none';

    while (<$file_handle>) {
        $_ =~ s/^\s+//;
        $_ =~ s/\s+$//;

        # Ignore comments and blank lines
        s/<!--(.*?)-->//g;
        next if (length($_) == 0);

        if ($state eq 'none') {
            if (m/^<autobuild>$/i) {
                $state = 'autobuild';
            }
            elsif (m/^<\?.*\?>/i) {
                # ignore
            }
            else {
                print STDERR "Error: Unexpected in state <$state>: $_\n";
                return 0;
            }
        }
        elsif ($state eq 'autobuild') {
            if (m/^<\/autobuild>$/i) {
                $state = 'none';
            }
            elsif (m/^<configuration>$/i) {
                $state = 'configuration';
            }
            elsif (m/^<command\s+name\s*=\s*"([^"]*)"(\s+options\s*=\s*"([^"]*)")?\s*\/\s*>$/i) {
                my %value = (NAME    => $1,
                             OPTIONS => (defined $3 ? $3 : ''));
                push @{$data->{COMMANDS}}, \%value;
            }
            else {
                print STDERR "Error: Unexpected in state <$state>: $_\n";
                return 0;
            }
        }
        elsif ($state eq 'configuration') {
            if (m/^<\/configuration>$/i) {
                $state = 'autobuild';
            }
            elsif (m/^<variable\s+name\s*=\s*"([^"]*)"\s+value\s*=\s*"([^"]*)"\s*\/\s*>$/i) {
                $data->{VARS}->{$1} = $2;
            }
            elsif (m/^<environment\s+name\s*=\s*"([^"]*)"\s+value\s*=\s*"([^"]*)"(\s+type\s*=\s*"([^"]*)")?\s*\/\s*>$/i) {
                my($type) = (defined $4 ? $4 'replace');
                if ($type ne 'replace' && $type ne 'prefix' && $type ne 'suffix') {
                    print STDERR "Error: environment type must be 'replace', 'prefix', or 'suffix'\n";
                    return 0;
                }

                my %value;
                $value{NAME} = $1;
                $value{VALUE} = $2;
                $value{TYPE} = $type;

                push @{$data->{ENVIRONMENT}}, \%value;
            }
            else {
                print STDERR "Error: Unexpected in state <$state>: $_\n";
                return 0;
            }
        }
        else {
            print STDERR "Error: Parser reached unknown state <$state>\n";
            return 0;
        }
    }

    return 1;
}

1;

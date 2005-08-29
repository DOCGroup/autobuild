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

    my $line  = '';
    my $state = 'none';

    while (<$file_handle>) {
        # Remove leading and trailing spaces
        $_ =~ s/^\s+//;
        $_ =~ s/\s+$//;

        # Append it to the current line
        $line .= ' ' . $_;

        # Remove comments.  This is a fairly safe way to deal with
        # multiple comments on the same line with non-commented text in
        # the middle.
        my($c) = pack('I', 1);
        while($line =~ s/-->/$c/) {
          ++$c;
        }
        for(my $i = pack('I', 1); ord($i) < ord($c); ++$i) {
          if ($line !~ s/<!--.*$i//) {
            $line =~ s/$i/-->/;
          }
        }

        # Skip over blank lines
        $line =~ s/^\s+//;
        next if (length($line) == 0);

        if ($state eq 'none') {
            if ($line =~ s/^<\s*autobuild\s*>//i) {
                $state = 'autobuild';
            }
            elsif ($line =~ s/^<\?.*\?>//i) {
                # ignore
            }
        }
        elsif ($state eq 'autobuild') {
            if ($line =~ s/^<\s*\/\s*autobuild\s*>//i) {
                $state = 'none';
            }
            elsif ($line =~ s/^<\s*configuration\s*>//i) {
                $state = 'configuration';
            }
            elsif ($line =~ s/^<\s*command\s+name\s*=\s*"([^"]*)"(\s+options\s*=\s*"([^"]*)")?\s*\/\s*>//i) {
                my %value = (NAME    => $1,
                             OPTIONS => (defined $3 ? $3 : ''));
                push @{$data->{COMMANDS}}, \%value;
            }
        }
        elsif ($state eq 'configuration') {
            if ($line =~ s/^<\s*\/\s*configuration\s*>//i) {
                $state = 'autobuild';
            }
            elsif ($line =~ s/^<\s*variable\s+name\s*=\s*"([^"]*)"\s+value\s*=\s*"([^"]*)"\s*\/\s*>//i) {
                $data->{VARS}->{$1} = $2;
            }
            elsif ($line =~ s/^<\s*environment\s+name\s*=\s*"([^"]*)"\s+value\s*=\s*"([^"]*)"(\s+type\s*=\s*"([^"]*)")?\s*\/\s*>//i) {
                my($type) = (defined $4 ? $4 : 'replace');
                if ($type ne 'replace' && $type ne 'prefix' && $type ne 'suffix') {
                    print STDERR "Error: environment type must be 'replace', 'prefix', or 'suffix'\n";
                    return 0;
                }

                my %value = (NAME  => $1,
                             VALUE => $2,
                             TYPE  => $type);

                push @{$data->{ENVIRONMENT}}, \%value;
            }
        }
        else {
            print STDERR "Error: Parser reached unknown state <$state>\n";
            return 0;
        }
    }


    if (length($line) != 0) {
      print STDERR "Error: Unable to parse line:\n$line\n";
    }

    return 1;
}

1;

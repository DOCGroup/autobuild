# $Id$

package ScoreboardParser;

use strict;
use warnings;

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

sub Parse ($\@)
{
    my $self = shift;
    my $file = shift;
    my $data = shift;
    
    my $group_name;
    my %build_info;
    
    my $file_handle = new FileHandle ($file, 'r');

    if (!defined $file_handle) {
        print STDERR __FILE__, ": Error Could not open file <$file>: $!\n";
        return 0;
    }

    my $state = 'none';

    while (<$file_handle>) {
        chomp;

        # Ignore comments and blank lines
        s/<!--(.*?)-->//g;
        next if (m/^\s*$/);

        if ($state eq 'none') {
            if (m/^\s*<scoreboard>\s*$/i) {
                $state = 'scoreboard';
            }
            elsif (m/^\s*<\?.*\?>\s*/i) {
                # ignore
            }
            else {
                print STDERR "Error: Unexpected in state <$state>: $_\n";
                return 0;
            }
        }
        elsif ($state eq 'scoreboard') {
            if (m/^\s*<\/scoreboard>\s*$/i) {
                $state = 'none';
            }
            elsif (m/^\s*<group>\s*$/i) {
                $state = 'group';
            }
            else {
                print STDERR "Error: Unexpected in state <$state>: $_\n";
                return 0;
            }
        }
        elsif ($state eq 'group') {
            if (m/^\s*<\/group>\s*$/i) {
                $group_name = undef;
                $state = 'scoreboard';
            }
            elsif (m/^\s*<name>(.*)<\/name>\s*$/i) {
                $group_name = $1;
            }
            elsif (m/^\s*<build>\s*$/i) {
                $state = 'build';
            }
            else {
                print STDERR "Error: Unexpected in state <$state>: $_\n";
                return 0;
            }
        }
        elsif ($state eq 'build') {
            if (m/^\s*<\/build>\s*$/i) {
                if (!defined %build_info->{NAME}) {
                    print STDERR "Error: All builds must have a name\n";
                    return 0;
                }
                
                %build_info->{GROUP} = $group_name;
                
                %{%{$data}->{%build_info->{NAME}}} = %build_info;
                %build_info = ();
                
                $state = 'group';
            }
            elsif (m/^\s*<name>(.*)<\/name>\s*$/i) {
                my $name = $1;
                if ($name =~ s/\s//g) {
                    print "Warning: Found whitespace in build name, shrinking \"$1\" to \"$name\"\n";
                }
                
                %build_info->{NAME} = $1;
            }
            elsif (m/^\s*<url>(.*)<\/url>\s*$/i) {
                %build_info->{URL} = $1;
                
                # Remove a trailing slash, if there is one
                %build_info->{URL} =~ s/\/$//;
            }
            elsif (m/^\s*<manual>(.*)<\/manual>\s*$/i) {
                %build_info->{MANUAL_LINK} = $1;
            }
            elsif (m/^\s*<orange>(.*)<\/orange>\s*$/i) {
                %build_info->{ORANGE_TIME} = $1;
            }
            elsif (m/^\s*<red>(.*)<\/red>\s*$/i) {
                %build_info->{RED_TIME} = $1;
            }
	    elsif (m/^\s*<pdf>(.*)<\/pdf>\s*$/i) {
		%build_info->{PDF} = $1;
	    }
	    elsif (m/^\s*<ps>(.*)<\/ps>\s*$/i) {
	 	%build_info->{PS} = $1;
	    }
	    elsif (m/^\s*<html>(.*)<\/html>\s*$/i) {
	 	%build_info->{HTML} = $1;
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

# $Id$

package IntegratedParser;

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
    my $global_build_name ='';
    my %build_info;

    my $file_handle = new FileHandle ($file, 'r');

    if (!defined $file_handle) {
        print STDERR __FILE__, ": Error Could not open file <$file>: $!\n";
        return 0;
    }

    my $state = 'none';

    while (<$file_handle>) {
        chomp;

        # Strip out a single-line comment
        s/<!--(.*?)-->//g;

        # Need to do something more fancy for a multi-line comment
        # First find the opening tag <--
        if(m/<!--/) {
           # After we find the opening tag, keep reading each character
           # until we hit the end tag -->
           $self->parse_comment($file_handle);
           next;
        }
        next if (m/^\s*$/);

        if(m/<preamble>/) {
            $self->parse_preamble($file_handle);
            next;
        }
        if ($state eq 'none') {
            if (m/^\s*<integrated>\s*$/i) {
                $state = 'integrated';
            }
            elsif (m/^\s*<\?.*\?>\s*/i) {
                # ignore
            }
            else {
                print STDERR "Error: Unexpected in state <$state>: $_\n";
                return 0;
            }
        }
        elsif ($state eq 'integrated') {
            if (m/^\s*<build_ace>\s*$/i){
                $global_build_name = 'ACE';
            }
            elsif (m/^\s*<build_tao>\s*$/i){
                $global_build_name = 'TAO';
            }
            elsif (m/^\s*<build_ciao>\s*$/i){
                $global_build_name = 'CIAO';
            }
            elsif (m/^\s*<build_dds>\s*$/i){
                $global_build_name = 'DDS';
            }
            elsif (m/^\s*<scoreboard>\s*$/i) {
                $state = 'scoreboard';
            }
            elsif (m/^\s*<\/integrated>\s*$/i) {
                $state = 'none';
            }
            else {
                print STDERR "Error: Unexpected in state <$state>: $_\n";
                return 0;
            }
        }
        elsif ($state eq 'scoreboard') {
            if (m/^\s*<\/scoreboard>\s*$/i) {
                $state = 'integrated';

                # Make the global name null
                $global_build_name = '';
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
                if (!defined $build_info{NAME}) {
                    print STDERR "Error: All builds must have a name\n";
                    return 0;
                }

                if ($global_build_name ne '') {
                    $build_info{GROUP} = $global_build_name.' On '.$group_name;
                } else {
                    $build_info{GROUP} = $group_name;
                }

		#%{%{$data}->{$build_info{NAME}}} = %build_info;
                #$data->{$build_info{NAME}} = %build_info;
		%{$data->{$build_info{NAME}}} = %build_info;
                %build_info = ();

                $state = 'group';
            }
            elsif (m/^\s*<name>(.*)<\/name>\s*$/i) {
                my $name = $1;
                if ($name =~ s/\s//g) {
                    print "Warning: Found whitespace in build name, shrinking \"$1\" to \"$name\"\n";
                }

                $build_info{NAME} = $1;
            }
            elsif (m/^\s*<url>(.*)<\/url>\s*$/i) {
                $build_info{URL} = $1;

                # Remove a trailing slash, if there is one
                $build_info{URL} =~ s/\/$//;
            }
            elsif (m/^\s*<build_sponsor>(.*)<\/build_sponsor>\s*$/i) {
                $build_info{BUILD_SPONSOR} = $1;
            }
            elsif (m/^\s*<build_sponsor_url>(.*)<\/build_sponsor_url>\s*$/i) {
                $build_info{BUILD_SPONSOR_URL} = $1;

                # Remove a trailing slash, if there is one
                #$build_info{BUILD_SPONSOR_URL} =~ s/\/$//;
            }
            elsif (m/^\s*<manual>(.*)<\/manual>\s*$/i) {
                $build_info{MANUAL_LINK} = $1;
            }
            elsif (m/^\s*<orange>(.*)<\/orange>\s*$/i) {
                $build_info{ORANGE_TIME} = $1;
            }
            elsif (m/^\s*<red>(.*)<\/red>\s*$/i) {
                $build_info{RED_TIME} = $1;
            }
            elsif (m/^\s*<diffroot>(.*)<\/diffroot>\s*$/i) {
                # Ignore
            }
	    elsif (m/^\s*<pdf>(.*)<\/pdf>\s*$/i) {
		$build_info{PDF} = $1;
	    }
	    elsif (m/^\s*<ps>(.*)<\/ps>\s*$/i) {
	 	$build_info{PS} = $1;
	    }
	    elsif (m/^\s*<html>(.*)<\/html>\s*$/i) {
	 	$build_info{HTML} = $1;
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



###############################################################################
# Before we call this function, we have already found the opening tag
# for an XML comment: <!--
# This function keeps parsing the stream until it finds the tag to terminate
# the comment: --> , and returns when it finds it.
#
# Arguments:  An open file stream.
#
# Returns:    Nothing
#
###############################################################################

sub parse_comment($)
{
  my $self = shift;
  my $result = shift;
  my @c;
  my $i=0;
  my $ch;

  while(1){
     $ch = $result->getc();

     # determine if we have hit an EOF or not
     if( ! defined $ch) {
        last; # break out of the whlie loop
     }

     $c[$i] = $ch;

     # Keep parsing character by character until we find "-->".
     # Perl doesn't support a portable version of ungetc, so we
     # need to keep our own buffer of characters to hold the "-->"
     # as we parse character by character.
     if($i >= 2) {
        my $tag="";
        $tag = join('', @c);
        if($tag eq "-->") {
          last;  # break out of the while loop
        }

        # Pop off the first element of the array and shift everything up
        shift(@c);
        $i=1;
     }
     ++$i;
   }
}

###############################################################################
# Before we call this function, we have already found the opening tag
# for an XML comment: <preamble>
# This function keeps parsing the stream until it finds the tag to terminate
# the comment: --> , and returns when it finds it.
#
# Arguments:  An open file stream.
#
# Returns:    Nothing
#
###############################################################################
sub parse_preamble($\@)
{
   my $self = shift;
   my $result = shift;
   my @c;
   my @buf;
   my $i=0;
   my $ch;

   while(1){
     $ch = $result->getc();

     # determine if we have hit an EOF or not
     if( ! defined $ch) {
        last; # break out of the whlie loop
     }

     $c[$i] = $ch;
     push(@buf, $ch);

     # Keep parsing character by character until we find "</preamble>".
     # Perl doesn't support a portable version of ungetc, so we
     # need to keep our own buffer of characters to hold the "</preamble>"
     # as we parse character by character.
     if($i > 9) {
        my $tag="";
        $tag = join('', @c);
        if($tag eq "</preamble>") {
          splice(@buf, -11 ); # remove "</preamble>" from @buf
          last;  # break out of the while loop
        }

        # Pop off the first element of the array and shift everything up
        shift(@c);
        $i=9;
     }
     ++$i;
   }
}

1;

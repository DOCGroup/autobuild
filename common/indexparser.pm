# $Id$

package IndexParser;

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

sub Parse ($)
{
    my $self = shift;
    my $file = shift;
    my $group_name;

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
            $main::preamble = $self->parse_preamble($file_handle);
            next;
        }
 
        if ($state eq 'none') {
            if (m/^\s*<intropage>\s*$/i) {
                $state = 'intropage';
            }
            elsif (m/^\s*<\?.*\?>\s*/i) {
                # ignore
            }
            else {
                print STDERR "Error: Unexpected in state <$state>: $_\n";
                return 0;
            }
        }
        elsif ($state eq 'intropage') {
            if (m/^\s*<\/intropage>\s*$/i) {
                $state = 'none';
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
sub parse_comment($\@)
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
# Returns:    All the text that is between the tags: <preamble> </preamble>
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
   return( join('', @buf)); 
}

1;

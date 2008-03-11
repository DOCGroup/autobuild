# $Id$

package SimpleParser;

use strict;
use FileHandle;
use File::Basename;
use POSIX qw(strftime);

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

my $nested_level = 0;

###############################################################################
# Methods

sub Parse ($\%)
{
    my ($self, $file, $data) = @_;

    my $nested_spaces = '  'x$nested_level;
    print "Parsing file:$nested_spaces$file\n" if ($main::verbose);

    my $date_string = strftime "%y%m%d", localtime;
    $data->{VARS}->{'date_string'} = $date_string;

    my $file_handle = new FileHandle ($file, 'r');

    if (!defined $file_handle) {
        print STDERR "Error: Could not open file <$file>: $!\n";
        return 0;
    }

    my $line  = '';
    my $state = 'none';

    my $lineNumberCurrent = 0;    ## Will be incremented after each line is read
    while (<$file_handle>) {
        ++$lineNumberCurrent;
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

        if ($line =~ s/^\s*<\s*include\s*name\s*=\s*"([^"]*)"\s*\/\s*>//i) {
            # <include name="some_file" /> tag - include the file.

            my $include_file = $1;

            # Test for the file as is, and if not found try prefixing
            # the path from current file.
            #
            if (!-e $include_file) {
              my $path= File::Spec->file_name_is_absolute ($file) ?
                        $file : File::Spec->rel2abs ($file);
              $path= File::Basename::dirname ($path);
              $include_file =
                $path .
                (($^O eq "MSWin32")? '\\' : '/') .
                $include_file;
            }

            # Save current state and set to zero
            my $oldstate = $state;
            $state = 'none';

            # Process the included file
            $nested_level++;
            $self->Parse($include_file, $data);
            $nested_level--;

            # Put the state back how we found it
            $state = $oldstate;
        }
        elsif ($state eq 'none') {
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
            elsif ($line =~ s/^<\s*command\s+name\s*=\s*"([^"]*)"(\s+options\s*=\s*"([^"]*)")?(\s+directory\s*=\s*"([^"]*)")?(\s+if\s*=\s*"([^"]*)")?\s*\/\s*>//i) {
                my %value = (NAME    => $1,
                             OPTIONS => (defined $3 ? $3 : ''),
                             DIRECTORY => (defined $5 ? $5 : ''),
                             IF_TEXT => (defined $7 ? $7 : ''),
                             FILE => $file,
                             LINE_FROM => $lineNumberCurrent,
                             );
                $value{OPTIONS} =~ s/\\x20/ /g;
                $value{OPTIONS} =~ s/\\x22/"/g;
                push @{$data->{COMMANDS}}, \%value;
            }
        }
        elsif ($state eq 'configuration') {
            if ($line =~ s/^<\s*\/\s*configuration\s*>//i) {
                $state = 'autobuild';
            }
            elsif ($line =~ s/^<\s*variable\s+name\s*=\s*"([^"]*)"\s+value\s*=\s*"([^"]*)"\s*\/\s*>//i) {                
                $data->{VARS}->{$1} = $2;
                print "$1 = $2\n" if $main::verbose;
            }
            elsif ($line =~ s/^<\s*variable\s+name\s*=\s*"([^"]*)"\s+default\s*=\s*"([^"]*)"\s*\/\s*>//i) {                
                if (not defined $data->{VARS}->{$1}) {               
                    $data->{VARS}->{$1} = $2;
                }
                print "$1 = $2\n" if $main::verbose;
            }
            elsif ($line =~ s/^<\s*variable\s+name\s*=\s*"([^"]*)"\s+relative_value\s*=\s*"([^"]*)"(\s+eval\s*=\s*"([^"]*)")?\s*\/\s*>//i) {
                my $res = main::subsituteVars($2);
                if (defined $3 and (uc $4 eq 'TRUE')) {
                    $res = eval $res;
                }
                $data->{VARS}->{$1} = $res;
                print "$1 = $data->{VARS}->{$1}\n" if $main::verbose;
            }
            elsif ($line =~ s/^<\s*variable\s+name\s*=\s*"([^"]*)"\s+environment\s*=\s*"([^"]*)"\s*\/\s*>//i) {                
                # If environment variable is not defined, set it to empty string value.
                my $val = $ENV{$2};
                if (!defined $val) {
                  $val = "";                  
                } 
                $data->{VARS}->{$1} = $val;
                print "$1 = $val\n" if $main::verbose;
            }
            elsif ($line =~ s/^<\s*environment\s+name\s*=\s*"([^"]*)"\s+value\s*=\s*"([^"]*)"(\s+type\s*=\s*"([^"]*)")?\s*\/\s*>//i) {
                my($type) = (defined $4 ? $4 : 'replace');
                if ($type ne 'replace' && $type ne 'ifundefined' && $type ne 'prefix' && $type ne 'suffix') {
                    print STDERR "Error: environment type must be 'replace', 'ifundefined', 'prefix', or 'suffix'\n";
                    return 0;
                }

                print "Env: $1 = $2\n" if $main::verbose;

                my %value = (NAME  => $1,
                             VALUE => $2,
                             TYPE  => $type);

                push @{$data->{ENVIRONMENT}}, \%value;
            }
            elsif ($line =~ s/^<\s*relative_env\s+name\s*=\s*"([^"]*)"\s+base_var\s*=\s*"([^"]*)"\s+suffix_var\s*=\s*"([^"]*)"\s+join\s*=\s*"([^"]*)"(\s+type\s*=\s*"([^"]*)")?\s*\/\s*>//i) {
                my($type) = (defined $6 ? $6 : 'replace');
                if ($type ne 'replace' && $type ne 'ifundefined' && $type ne 'prefix' && $type ne 'suffix') {
                    print STDERR "Error: environment type must be 'replace', 'ifundefined', 'prefix', or 'suffix'\n";
                    return 0;
                }

                if (! defined $data->{VARS}->{$2}) {
                    print STDERR "Error: Variable $2 is not defined at line: \n" . $_ . "\n";
                    return 0;
                }

                if (! defined $data->{VARS}->{$3}) {
                    print STDERR "Error: Variable $3 is not defined at line: \n" . $_ . "\n";
                    return 0;
                }

                my($propval) = $data->{VARS}->{$2} . $4 . $data->{VARS}->{$3};

                my %value = (NAME  => $1,
                             VALUE => $propval,
                             TYPE  => $type );

                push @{$data->{ENVIRONMENT}}, \%value;
            }
            elsif ($line =~ s/^<\s*relative_var\s+name\s*=\s*"([^"]*)"\s+base_var\s*=\s*"([^"]*)"\s+suffix_var\s*=\s*"([^"]*)"(\s+join\s*=\s*"([^"]*)")?\s*\/\s*>//i) {
                my($join) = (defined $5 ? $5 : "");

                if (! defined $data->{VARS}->{$2}) {
                    print STDERR "Error: Variable $2 is not defined at line: \n" . $_ . "\n";
                    return 0;
                }

                if (! defined $data->{VARS}->{$3}) {
                    print STDERR "Error: Variable $3 is not defined at line: \n" . $_ . "\n";
                    return 0;
                }

                my($varval) = $data->{VARS}->{$2} . $join . $data->{VARS}->{$3};

                $data->{VARS}->{$1} = $varval;
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

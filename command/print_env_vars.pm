#
# $Id$
#

package print_env_vars;

use strict;
use warnings;

use Cwd;

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

    return 1;
}

##############################################################################

sub Run ($)
{
    my $self = shift;
    my $options = shift;

    main::PrintStatus ('Config', "print Environment Variables" );

    print "<h3>" . ($options eq '' ? "Environment:" : $options) . "</h3>\n";
    my $name;
    if ($^O eq 'VMS') {
      foreach my $envvar (main::GetEnvironment ()) {
        my $VALUE= "$envvar->{NAME}=$ENV{$envvar->{NAME}}\n";
        # Escape any '<' or '>' signs
        $VALUE =~ s/</&lt;/sg;
        $VALUE =~ s/>/&gt;/sg;
        print $VALUE;
      }
    }
    else {
      foreach $name (sort keys %ENV) {
          my $VALUE= "$name=$ENV{$name}\n";
          # Escape any '<' or '>' signs
          $VALUE =~ s/</&lt;/sg;
          $VALUE =~ s/>/&gt;/sg;
          print $VALUE;
      }
    }
    print "\n";

    return 1;
}

##############################################################################

main::RegisterCommand ("print_env_vars", new print_env_vars());

#
# $Id$
#

package print_tool_version;

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

    $self->{tool} = shift;
    $self->{args} = shift;

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
    my $remote = 0;

    my $remote_shell = main::GetVariable ('remote_shell');
    
    if ($options =~ m/^remote([ \t]+|$)/) {
        $remote = 1;
        $options =~ s/^remote[ \t]*//;
        
        if (!defined $remote_shell) {
          print "WARNING: no remote_shell variable defined!\n";
          return 1;
        }
    }

    main::PrintStatus ('Config', $remote ? 
      "print Remote " . $self->{tool} . " version - remote shell=$remote_shell" : 
      "print " . $self->{tool} . " version" );

    print "<h3>", $self->{tool}, " version (", $self->{tool}, " ", $self->{args}, ")</h3>\n";
    if ($remote) {
        system("$remote_shell " . $self->{tool} . " " . $self->{args});
    } else {
        system($self->{tool} . " " . $self->{args});
    }
    
    return 1;
}

##############################################################################

main::RegisterCommand ("print_purify_version", new print_tool_version("purify", "-version"));
main::RegisterCommand ("print_quantify_version", new print_tool_version("quantify", "-version"));
main::RegisterCommand ("print_valgrind_version", new print_tool_version("valgrind", "--version"));
main::RegisterCommand ("print_perl_version", new print_tool_version("perl", "-V"));

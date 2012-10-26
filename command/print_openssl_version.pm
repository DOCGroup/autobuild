#
# $Id$
#

package print_openssl_version;

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
    my $remote = 0;
    my $remote_shell = main::GetVariable ('remote_shell');

    if ($options =~ m/remote/) {
        $remote = 1;
        if (!defined $remote_shell) {
          print "WARNING: no remote_shell variable defined!\n";
          return 1;
        }
    }

    main::PrintStatus ('Config', $remote ?
      "print Remote OpenSSL version - remote shell=$remote_shell" :
      "print " OpenSSL version" );

    print "<h3>OpenSSL version (openssl version)</h3>\n";
    if ($remote) {
        print "Remote shell: $remote_shell\n";
        system ("$remote_shell openssl version");
    } else {
        if (defined $ENV{SSL_ROOT}) {
            if (-x "$ENV{SSL_ROOT}/bin/openssl") {
                system ("$ENV{SSL_ROOT}/bin/openssl version");
                return 1;
            } elsif (-x "$ENV{SSL_ROOT}/out32dll/openssl.exe") {
                system ("$ENV{SSL_ROOT}/out32dll/openssl.exe version");
                return 1;
            }
        }

        #if no env var "SSL_ROOT" then we expect to find openssl on the PATH
        system ('openssl version');
    }
    return 1;
}

##############################################################################

main::RegisterCommand ("print_openssl_version", new print_openssl_version ());

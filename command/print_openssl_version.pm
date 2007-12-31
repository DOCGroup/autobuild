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

    main::PrintStatus ('Config', "print OpenSSL Version" );

    print "<h3>OpenSSL version (openssl version)</h3>\n";
    if (defined $ENV{SSL_ROOT}) {
        system("$ENV{SSL_ROOT}/bin/openssl version");
    } else {
        #if no env var "SSL_ROOT" then we expect to find openssl on the PATH
        system('openssl version');
    }

    return 1;
}

##############################################################################

main::RegisterCommand ("print_openssl_version", new print_openssl_version());

#
# $Id$
#
package Matrix_Prettify::Handler;
use strict;
use warnings;

sub new($) {
  my $class = shift;
  my $self = {};

  bless ($self, $class);
  return $self;
}

sub Header() {
}

sub Footer() {
}

sub Section($) {
}

sub Description($) {
}

sub Timestamp($) {
}


sub Subsection($) {
}

sub Error($) {
}

package Matrix_Prettify;



use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/../common";

use prettify;
use base qw(Prettify);

sub new($) {
  my $class = shift;
  my $self = $class->SUPER::new(@_);

  @{$self->{OUTPUT}} =
    (
     new Matrix::Handler;
    );

  return 
}

1

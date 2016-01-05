package ORION::C::Variable;

use strict;
use warnings;

use Moo;

has [qw(type name)] => ( is => 'ro', required => 1 );

1;

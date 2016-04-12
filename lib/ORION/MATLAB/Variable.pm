package ORION::MATLAB::Variable;

use strict;
use warnings;

use Moo;

has [qw(name)] => ( is => 'ro', required => 1 );

1;

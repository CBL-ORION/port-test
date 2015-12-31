package ORION::FunctionParam;

use Moo;
use Types::Standard -types;

has name     => ( is => 'ro', required => 1, isa => Str );
has position => ( is => 'ro', required => 1, isa => Int );

has data_type => ( is => 'rw', isa => Str );


1;

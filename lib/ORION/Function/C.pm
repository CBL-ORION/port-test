package ORION::Function::C;

use Moo;
use Types::Standard -types;

has prototype => ( is => 'ro', required => 1, isa => Str );


has name => ( is => 'lazy', isa => Str );
has 'params' => ( is => 'lazy' , isa => ArrayRef );

has language => ( is => 'ro', isa => Str, default => sub { "C" } );

with qw(ORION::Role::FunctionRole);

sub _build_name {
	...
}

sub _build_params {
	...
}

1;

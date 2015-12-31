package ORION::Function::MATLAB;

use Moo;

has function_head => ( is => 'ro', required => 1, isa => Str );

has name => ( is => 'lazy', isa => Str );
has 'params' => ( is => 'lazy' , isa => ArrayRef );

with qw(ORION::Role::FunctionRole);

sub _build_name {
	...
}

sub _build_params {
	...
}

1;

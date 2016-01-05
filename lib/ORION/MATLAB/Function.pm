package ORION::MATLAB::Function;

use Moo;
use Types::Standard -types;

use ORION::MATLAB::Variable;

has name => ( is => 'ro', required => 1, isa => Str );
has [ qw(params output_params) ] => ( is => 'ro',isa => ArrayRef, default => sub { [] } );

has language => ( is => 'ro', isa => Str, default => sub { "MATLAB" } );

with qw(ORION::Role::FunctionRole);

sub new_from_parser_data {
	my ($class, $data) = @_;
	$class->new(
		name => $data->{name},
		params => [
			map {
				ORION::MATLAB::Variable->new( name => $_,)
			} @{ $data->{input_param} }
		],
		output_params => [
			map {
				ORION::MATLAB::Variable->new( name => $_,)
			} @{ $data->{output_params} }
		],
	);
}

1;

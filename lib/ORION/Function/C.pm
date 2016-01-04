package ORION::Function::C;

use Moo;
use Types::Standard -types;

use ORION::Variable::C;
use ORION::Type::C;

has name => ( is => 'ro', required => 1, isa => Str );
has 'params' => ( is => 'ro', required => 1, isa => ArrayRef );
has return_type => ( is => 'ro', required => 1 );

has language => ( is => 'ro', isa => Str, default => sub { "C" } );

with qw(ORION::Role::FunctionRole);

sub new_functions_from_parser_data {
	my ($class, $data) = @_;
	my @functions;
	for my $function_name (keys %{ $data->{function} }) {
		my $f_data = $data->{function}{$function_name};
		push @functions, $class->new(
			name => $function_name,
			params => [
				map {
					ORION::Variable::C->new(
						type => ORION::Type::C->new( decl => $f_data->{arg_types}[$_] ),
						name => $f_data->{arg_names}[$_],
					)
				} 0..@{ $f_data->{arg_names} }-1
			],
			return_type => ORION::Type::C->new( decl => $f_data->{return_type} ),
		);

	}
	return \@functions;
}

1;

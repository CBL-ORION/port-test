package ORION::C::Function;

use Moo;
use Types::Standard -types;

use ORION::C::Variable;
use ORION::C::Type;

has name => ( is => 'ro', required => 1, isa => Str );
has 'params' => ( is => 'ro', required => 1, isa => ArrayRef );
has return_type => ( is => 'ro', required => 1 );

has prototype => ( is => 'lazy', isa => Str );

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
					ORION::C::Variable->new(
						type => ORION::C::Type->new( decl => $f_data->{arg_types}[$_] ),
						name => $f_data->{arg_names}[$_],
					)
				} 0..@{ $f_data->{arg_names} }-1
			],
			return_type => ORION::C::Type->new( decl => $f_data->{return_type} ),
		);

	}
	return \@functions;
}

sub _build_prototype {
	my ($self) = @_;
	return <<"C";
extern @{[ $self->return_type->decl ]} @{[ $self->name ]} (
	@{[ join ", ", map { $_->cstr } @{ $self->params } ]}
);
C
}

1;

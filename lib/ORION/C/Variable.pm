package ORION::C::Variable;

use strict;
use warnings;

use Moo;

has [qw(type name)] => ( is => 'ro', required => 1 );

has [qw(cstr unqualified_type_cstr)] =>  ( is => 'lazy' );

sub _build_cstr {
	my ($self) = @_;

	# varargs does not have a separate type
	return $self->name if $self->name eq '...';

	return "@{[ $self->type->decl ]} @{[ $self->name ]}";
}

sub _build_unqualified_type_cstr {
	my ($self) = @_;

	# varargs does not have a separate type
	return $self->name if $self->name eq '...';

	return "@{[ $self->type->unqualified_type ]} @{[ $self->name ]}";
}

1;

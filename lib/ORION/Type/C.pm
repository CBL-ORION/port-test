package ORION::Type::C;

use strict;
use warnings;
use Moo;

has decl => ( is => 'ro' );

has [ qw(is_const unqualified_type) ] =>  ( is => 'lazy' );

sub _build_is_const {
	my ($self) = @_;
	return $self->decl =~ /^const\b/;
}

sub _build_unqualified_type {
	my ($self) = @_;
	$self->decl =~ s/((const|volatile)\s+)*//r;
}

1;

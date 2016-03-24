package ORION::C::Type;

use strict;
use warnings;
use Moo;

has decl => ( is => 'ro' );

has [ qw(is_const is_ptr unqualified_type) ] =>  ( is => 'lazy' );

sub _build_is_const {
	my ($self) = @_;
	return $self->decl =~ /^const\b/;
}

sub _build_is_ptr {
	my ($self) = @_;
	return $self->unqualified_type =~ /\*$/;
}

sub _build_unqualified_type {
	my ($self) = @_;
	$self->decl =~ s/((const|volatile)\s+)*//r;
}

1;

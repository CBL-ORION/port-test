package ORION::FunctionStateFile;

use strict;
use warnings;

use Moo;
use Path::Tiny;
use Data::MATLAB;

has [ qw(directory) ] => ( is => 'ro', required => 1 );
has [ qw(name stack_id) ] => ( is => 'rw', required => 1 );

has [ qw(_input_file _output_file) ] => ( is => 'lazy' );
has [ qw(_input_data _output_data) ] => ( is => 'lazy' );

has [ qw(start_time stop_time stack_trace) ] => ( is => 'lazy' );

has [ qw(input output) ] => ( is => 'lazy' );

sub _build__input_file {
	my ($self) = @_;
	$self->directory->child(
		"@{[ $self->name ]}.F_BEGIN.@{[ $self->stack_id ]}.mat"
	);
}

sub _build__output_file {
	my ($self) = @_;
	$self->directory->child(
		"@{[ $self->name ]}.F_END.@{[ $self->stack_id ]}.mat"
	);
}

sub _build__input_data {
	my ($self) = @_;
	my $p_input = Data::MATLAB->read_data( $self->_input_file );
}

sub _build__output_data {
	my ($self) = @_;
	my $p_output = Data::MATLAB->read_data( $self->_output_file );
}

sub _build_stack_trace {
	my ($self) = @_;
	my $p_input = $self->_input_data;
	$p_input->{caller_state}[0]{STACK};
}

sub _build_start_time {
	my ($self) = @_;
	$self->_input_data->{caller_state}[0]{TIME}->squeeze;
}

sub _build_stop_time {
	my ($self) = @_;
	$self->_output_data->{caller_state}[0]{TIME}->squeeze;
}

sub _build_input {
	my ($self) = @_;
	my $p_input = $self->_input_data;
	return $p_input->{caller_state}[0]{input}[0];
}

sub _build_output {
	my ($self) = @_;
	my $p_output = $self->_output_data;
	return $p_output->{caller_state}[0]{output}[0];
}


sub new_from_from_filename {
	my ($class, $path) = @_;
	$path = path($path);
	my $filename = $path->basename;
	my $filename_pattern = qr/
		(?<name>[^.]+)
		\.
		(?<where>[^.]+)
		\.
		(?<id>[^.]+)
		\.mat$/x;
	unless( $filename =~ /$filename_pattern/ ) {
		die "filename does not contain parts for function name and stack id";
	}

	$class->new( directory => $path->parent, stack_id => $+{id}, name => $+{name} );
}

1;

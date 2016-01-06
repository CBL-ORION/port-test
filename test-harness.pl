#!/usr/bin/env perl

use strict;
use warnings;

use v5.16;
use lib 'lib';
use PDL;
use Data::MATLAB;
use ORION;
use ORION::FunctionStateFile;
use ORION::Types;

sub main {
	my $debug_trace_dir = ORION->datadir->child(qw(debug-trace));
	my $mat_file_rule = Path::Iterator::Rule->new
		->file->name( qr/F_BEGIN.*\.mat$/ );
	my $mat_file_iter = $mat_file_rule->iter( $debug_trace_dir );

	my $data_by_function;
	while( defined( my $mat_file = $mat_file_iter->() ) ) {
		#say $mat_file;
		my $f = ORION::FunctionStateFile->new_from_from_filename($mat_file);
		#use DDP; p $f;
		push @{ $data_by_function->{$f->name} }, $f;
	}
	do_hdaf_analysis($data_by_function->{hdaf});
}

sub do_hdaf_analysis {
	my ($all_hdaf_data) = @_;
	my $matlab_hdaf = ( grep { $_->name eq 'hdaf' } @{ ORION->matlab_functions } )[0];
	my $c_hdaf = ( grep { $_->name eq 'orion_hdaf' } @{ ORION->c_functions } )[0];
	#use DDP; p $matlab_hdaf;
	#use DDP; p $c_hdaf;
	for my $hdaf_function_data (@$all_hdaf_data) {
		compare_hdaf( $hdaf_function_data, $matlab_hdaf, $c_hdaf );
	}
}

sub compare_hdaf {
	my ($fs_file, $m, $c) = @_;
	my $matlab_param = [ map { $_->name } @{ $m->params } ];
	my $c_param = [ map { $_->name } @{ $c->params } ];
	my $c_param_type = [ map { $_->type } @{ $c->params } ];
	my $matlab_input_values = $fs_file->input;
	my $matlab_output_values = $fs_file->output;

	my $c_input_values = [
		map {
			ORION::Types->coerce_type(
				$c_param_type->[$_],
				$matlab_input_values->{$matlab_param->[$_]})
		} 0..@$matlab_param-1 ];

	my $expected_c_output = $matlab_output_values->{val};

	my $got_c_output = ORION::orion_hdaf( @$c_input_values );

	#use DDP; p $expected_c_output->slice(':10,:10,:10');
	#use DDP; p $got_c_output->slice(':10,:10,:10');

	my $diff = abs($expected_c_output - $got_c_output);
	use DDP; p $diff->max;
}

main;
#__DATA__
#__C__


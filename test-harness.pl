#!/usr/bin/env perl

use strict;
use warnings;

use v5.16;
use lib 'lib';
use PDL;
use Data::MATLAB;
use ORION;
use ORION::FunctionStateFile;

#use Inline Config =>
	#enable => force_build =>
	#enable => build_noisy =>
	#disable => clean_after_build =>;

use Inline C => 'DATA',
	ENABLE => AUTOWRAP =>
	with => ['ORION'],
	;

my $debug_trace_dir = ORION->datadir->child(qw(debug-trace));
my $mat_file_rule = Path::Iterator::Rule->new
	->file->name( qr/F_BEGIN.*\.mat$/ );
my $mat_file_iter = $mat_file_rule->iter( $debug_trace_dir );

while( defined( my $mat_file = $mat_file_iter->() ) ) {
	#say $mat_file;
	my $f = ORION::FunctionStateFile->new_from_from_filename($mat_file);
	#use DDP; p $f;
	if( $f->name eq 'hdaf' ) {
		run_hdaf_analysis( $f );
	}
}

sub run_hdaf_analysis {
	my ($fs_file) = @_;
	my $matlab_param = [ 'n', 'c_nk', 'x' ];
	my $c_param = [ 'hdaf_approx_degree', 'scaling_constant', 'x' ];
	my $matlab_input_values = $fs_file->input;
	my $matlab_output_values = $fs_file->output;

	my $c_input_values = [ $matlab_input_values->{n}->squeeze->float,
		$matlab_input_values->{c_nk}->squeeze->float,
		$matlab_input_values->{x}->float, ];

	my $expected_c_output = $matlab_output_values->{val};

	my $got_c_output = orion_hdaf( @$c_input_values );

	#use DDP; p $expected_c_output->slice(':10,:10,:10');
	#use DDP; p $got_c_output->slice(':10,:10,:10');

	my $diff = abs($expected_c_output - $got_c_output);
	use DDP; p $diff->max;
}

__DATA__
__C__

#include "ndarray/ndarray3.h"
/*#include "kitchen-sink/01_Segmentation/dendrites_main/DetectTrainingSet/IsotropicFilter/hdaf.h"*/

extern ndarray3* orion_hdaf(
		int hdaf_approx_degree,
		float scaling_constant,
		ndarray3* x);

#!/usr/bin/env perl

use strict;
use warnings;

use v5.16;
use lib 'lib';
use PDL;
use Data::MATLAB;
use ORION;

#use Inline Config =>
	#enable => force_build =>
	#enable => build_noisy =>
	#disable => clean_after_build =>;

use Inline C => 'DATA',
	ENABLE => AUTOWRAP =>
	with => ['ORION'],
	;

my $p_input = Data::MATLAB->read_data( 'data/debug-trace/hdaf.F_BEGIN.32b30b3b-e2a9-4c04-8cc1-68086684c815.mat' );
my $p_output = Data::MATLAB->read_data( 'data/debug-trace/hdaf.F_END.32b30b3b-e2a9-4c04-8cc1-68086684c815.mat' );
#use DDP; p $p_input;
#use DDP; p $p_output;

my $matlab_param = [ 'n', 'c_nk', 'x' ];
my $c_param = [ 'hdaf_approx_degree', 'scaling_constant', 'x' ];
my $matlab_input_values = $p_input->{caller_state}[0]{input}[0];
my $matlab_output_values = $p_output->{caller_state}[0]{output}[0];

my $c_input_values = [ $matlab_input_values->{n}->squeeze->float,
	$matlab_input_values->{c_nk}->squeeze->float,
	$matlab_input_values->{x}->float, ];

my $expected_c_output = $matlab_output_values->{val};

my $got_c_output = orion_hdaf( @$c_input_values );

use DDP; p $expected_c_output->slice(':10,:10,:10');
use DDP; p $got_c_output->slice(':10,:10,:10');

my $diff = abs($expected_c_output - $got_c_output);
use DDP; p $diff;

__DATA__
__C__

#include "ndarray/ndarray3.h"
/*#include "kitchen-sink/01_Segmentation/dendrites_main/DetectTrainingSet/IsotropicFilter/hdaf.h"*/

extern ndarray3* orion_hdaf(
		int hdaf_approx_degree,
		float scaling_constant,
		ndarray3* x);

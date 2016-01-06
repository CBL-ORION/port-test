#!/usr/bin/env perl

use strict;
use warnings;

use v5.16;
use lib 'lib';
use PDL;
use Data::MATLAB;
use ORION;
use ORION::FunctionCompare;

sub main {
	do_hdaf_analysis();
}

sub do_hdaf_analysis {
	my $matlab_hdaf = ( grep { $_->name eq 'hdaf' } @{ ORION->matlab_functions } )[0];
	my $c_hdaf = ( grep { $_->name eq 'orion_hdaf' } @{ ORION->c_functions } )[0];

	my $f_compare = ORION::FunctionCompare->new(
		matlab_function => $matlab_hdaf,
		c_function => $c_hdaf,
	);

	my $all_hdaf_data = $f_compare->function_states;
	for my $hdaf_function_data (@$all_hdaf_data) {
		$f_compare->compare_state( $hdaf_function_data );
	}
}

main;
#__DATA__
#__C__


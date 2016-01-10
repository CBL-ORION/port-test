#!/usr/bin/env perl

use strict;
use warnings;

use v5.16;
use lib 'lib';
use ORION;
use Log::Log4perl qw(:easy);

sub main {
	Log::Log4perl->easy_init($DEBUG);
	my $function_compare_by_name = ORION->build_function_comparisons();
	#my $fss = $function_compare_by_name->{hdaf}->function_states;
	compare_all_function_states( $function_compare_by_name->{Makefilter} );
	#compare_all_function_states( $function_compare_by_name->{hdaf} );
}

sub compare_function_states_for_function {
	my ($f_compare) = @_;

	my $all_data = $f_compare->function_states;
	my $diffs = {};
	for my $function_data (@$all_data) {
		INFO "Comparing @{[ $f_compare->c_function->name ]}.@{[ $function_data->stack_id ]}";
		$diffs->{$function_data->stack_id}{diff} = $f_compare->compare_state( $function_data );
		$diffs->{$function_data->stack_id}{state} = $function_data;
		$function_data->clear_data;
	}

	$diffs;
}

main;

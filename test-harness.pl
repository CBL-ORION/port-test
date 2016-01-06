#!/usr/bin/env perl

use strict;
use warnings;

use v5.16;
use lib 'lib';
use PDL;
use Data::MATLAB;
use ORION;
use ORION::FunctionCompare;
use Path::Tiny;
use Log::Log4perl qw(:easy);

sub main {
	Log::Log4perl->easy_init($DEBUG);
	my $function_compare_by_name = build_function_comparisons();
	#compare_all_function_states( $function_compare_by_name->{Makefilter} );
	compare_all_function_states( $function_compare_by_name->{hdaf} );
}

sub build_function_comparisons {
	my $matlab_functions_by_name = {
		map { ( $_->name => $_ ) }
		@{ ORION->matlab_functions } };
	my $c_functions_by_name = {
		map { ( $_->name => $_ ) }
		@{ ORION->c_functions } };

	my $debug_trace_dir = ORION->function_state_dir;
	my $mat_file_rule = Path::Iterator::Rule->new
		->file->name( qr/F_BEGIN.*\.mat$/ );
	my $mat_file_iter = $mat_file_rule->iter( $debug_trace_dir );

	my $function_names;
	INFO "Reading list of function names from the function state data directory";
	while( defined( my $mat_file = $mat_file_iter->() ) ) {
		# the first part of the filename is the function name
		my $f_name = ( path($mat_file)->basename =~ /^([^.]+)/ )[0];
		$function_names->{$f_name} = 1;
	}

	my $function_compare_by_name = {};
	my $m_func_not_matched;
	for my $m_func_name (keys %$function_names) {
		my $c_func_name = "orion_$m_func_name";
		if( exists $c_functions_by_name->{$c_func_name} ) {
			$function_compare_by_name->{$m_func_name} =
				ORION::FunctionCompare->new(
					matlab_function => $matlab_functions_by_name->{$m_func_name},
					c_function => $c_functions_by_name->{$c_func_name},
				);
		} else {
			push @$m_func_not_matched, $m_func_name;
		}
	}

	# TODO need to examine $m_func_not_matched
	LOGWARN "There are @{[ scalar @$m_func_not_matched ]} MATLAB functions that do not have corresponding C functions";

	$function_compare_by_name;
}

sub compare_all_function_states {
	my ($f_compare) = @_;

	my $all_data = $f_compare->function_states;
	for my $function_data (@$all_data) {
		$f_compare->compare_state( $function_data );
	}
}

main;
#__DATA__
#__C__


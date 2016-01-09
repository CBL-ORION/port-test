#!/usr/bin/env perl

use strict;
use warnings;

use v5.16;
use lib 'lib';
use ORION;
use ORION::FunctionCompare;
use YAML::XS qw(LoadFile DumpFile);
use Log::Log4perl qw(:easy);

sub main {
	Log::Log4perl->easy_init($DEBUG);
	process_function_states_and_dump_stack_traces();
	#build_call_graph();
}

sub stack_traces_path {
	my $stack_trace_path = ORION->function_state_dir->child('stack-traces.yml');
}

sub process_function_states_and_dump_stack_traces {
	my $m_func_names = ORION->get_function_names_from_function_state_data();
	my @comparisons = map {
		# we do not need the C function name for this
		ORION::FunctionCompare->new(
			matlab_function => ORION::MATLAB::Function->new( name => $_ ),
			c_function => "" );
	} @$m_func_names;

	my $stack_traces;
	my $stack_trace_path = stack_traces_path();

	if( -r $stack_trace_path ) {
		$stack_traces = LoadFile( $stack_trace_path );
	}

	INFO "Processing all the functions";
	for my $function_compare (@comparisons) {
		my @function_states =  @{ $function_compare->function_states };
		for my $function_state (@function_states) {
			next if exists $stack_traces->{ $function_state->stack_id };

			INFO "Now processing function state: @{[ $function_state->name ]}.@{[ $function_state->stack_id ]}";

			$stack_traces->{ $function_state->stack_id } = {
				map { $_ => $function_state->$_ }
					qw(directory name stack_id stack_trace start_time stop_time)
			};

			# write the data now
			DumpFile( $stack_trace_path, $stack_traces );
		}
		$function_compare->clear_function_states;
	}
	DumpFile( $stack_trace_path, $stack_traces );
	INFO "Done processing all the functions";
}

sub build_call_graph {
	my $stack_trace_path = stack_trace_path();
	my $stack_traces = LoadFile( $stack_trace_path );

	...
}


main;

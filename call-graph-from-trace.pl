#!/usr/bin/env perl

use strict;
use warnings;

use v5.16;
use lib 'lib';
use ORION;
use ORION::FunctionCompare;
use ORION::FunctionStateFile;
use YAML::XS qw(LoadFile DumpFile);
use Log::Log4perl qw(:easy);
use Tree::Simple;

sub main {
	Log::Log4perl->easy_init($DEBUG);
	process_function_states_and_dump_stack_traces();
	build_call_graph();
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
	my $stack_trace_path = ORION->stack_traces_path();

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
	my $stack_trace_path = ORION->stack_traces_path();
	my $stack_traces = LoadFile( $stack_trace_path );

	INFO "Constructing call graph nodes (as a tree of stack frames)";
	my $tree_nodes = { map {
		my $fs = ORION::FunctionStateFile->new(
			directory => $stack_traces->{$_}{directory},
			name => $stack_traces->{$_}{name},
			stack_id => $stack_traces->{$_}{stack_id},
		);
		($_ => Tree::Simple->new( $fs ));
	} keys %$stack_traces };

	INFO "Walking the tree of stack frames to set up parent-child relationships";
	my $root_node;
	for my $st_key (keys %$stack_traces) {
		my $st_trace = $stack_traces->{$st_key}{stack_trace};
		my $st_node = $tree_nodes->{$st_key};
		if( @$st_trace >= 2 ) {
			my $parent_key = $st_trace->[-2]{id};
			$tree_nodes->{$parent_key}->addChild($st_node);
		} else {
			# this is the root node
			$root_node = $st_node;
		}
	}

	INFO "Saving call graph data";
	my $call_graph_path = ORION->call_graph_path();
	DumpFile( $call_graph_path, $root_node );
}


main;

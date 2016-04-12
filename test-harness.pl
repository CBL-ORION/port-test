#!/usr/bin/env perl

use strict;
use warnings;

use v5.16;
use lib 'lib';
use ORION;
use YAML::XS qw(LoadFile DumpFile);
use Log::Log4perl qw(:easy);

sub main {
	Log::Log4perl->easy_init($DEBUG);

	compare_function_states();

	#my $fss = $function_compare_by_name->{hdaf}->function_states;
	#my $d = compare_function_states_for_function( $function_compare_by_name->{Makefilter} );
	#use DDP; p $d;
	#use DDP; p $function_compare_by_name->{hdaf}->function_states->[0]->input;
	#my $d = compare_function_states_for_function( $function_compare_by_name->{hdaf} );
	#use DDP; p $d;
}

sub traverse_call_graph {
	my $call_graph_path = ORION->call_graph_path;
	die "Need to generate call graph first. Please run ./call-graph-from-trace.pl"
		unless -r $call_graph_path;
	my $root_node = LoadFile( $call_graph_path );

	use DDP; p $root_node;

	# Steps:
	#
	# 1. Traverse the tree until you get to the leaf node.
	# 2. Compare the
	# 3. Make note of functions that either read or write to disks (grep fopen)
	#    R: getInfoVolume, VolCrop2, readSWC readinformationOR3 RAWfromMHD
	#    W: createAvizoVisualization, exportAmiraRegistrationParameters SWCtoVTK SWCtoVTKSurface createVisualizationFromSWC writeSWC
        #       createInputFileDIADEM3 createInputFileDIADEM4 createInputFileDIADEM4 createInputFileDIADEM5 createInputFileDIADEM5 getReconstructionTime manual_threshold_segmentation_GUI
        #       WriteRAWandMHD
	#
	#    These

}

sub compare_function_states {
	my $function_compare_by_name = ORION->build_function_comparisons();

	#delete $function_compare_by_name->{ORION3_Dendrites};
	use DDP; p $function_compare_by_name;

	my $diff_path = ORION->diff_path;
	my $diff_data;
	if( -r $diff_path ) {
		$diff_data = LoadFile( $diff_path );
	}

	for my $f_compare (values %$function_compare_by_name) {
		my $m_name = $f_compare->matlab_function->name;

		next if exists $diff_data->{$m_name};

		INFO "Running comparison on states of $m_name";
		my $diff = compare_function_states_for_function($f_compare);

		$diff_data->{$m_name} = $diff;

		DumpFile( $diff_path, $diff_data );
	}
}

sub compare_function_states_for_function {
	my ($f_compare) = @_;

	my $all_data = $f_compare->function_states;
	my $diffs = {};
	for my $function_data (@$all_data) {
		INFO "Comparing @{[ $f_compare->matlab_function->name ]}.@{[ $function_data->stack_id ]}";
		$diffs->{$function_data->stack_id}{diff} = $f_compare->compare_state( $function_data );
		$diffs->{$function_data->stack_id}{state} = $function_data;
		$function_data->clear_data;
	}

	$diffs;
}

main;

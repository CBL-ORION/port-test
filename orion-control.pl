#!/usr/bin/env perl

use strict;
use warnings;

use lib 'lib';
use ORION;
use Expect;

# NOTE: We need MATLAB + JVM so that `gen_guid` and `tempname` works, so we do
# not use `-nojvm` here.
my $command = Expect->spawn("matlab", qw(-nodesktop -nodisplay -nosplash))
	or die "Couldn't start program: $!\n";


my $matlab_source = ORION->matlabsrcdir;
my $project = ORION->orionmatdir;
my $debug_trace_dir = ORION->datadir->child(qw(debug-trace));
my $orion3mat_test_data_conf = ORION->oriondir->child(qw(test-data DIADEM NPF Input_NPF023_D.txt));
$debug_trace_dir->mkpath;
my $SETUP_EXEC = join ",", (
	"addpath('$matlab_source')",
	"otrace('$project', 'ORION3(''$orion3mat_test_data_conf'')')",
);

say $command $SETUP_EXEC;

$command->debug( 2 );

while ( $command->expect(undef, '>>' ) ) {
	say $command "dump_state('$debug_trace_dir'), dbcont";

	# exit on error
	last if $command->before =~ /Error/;
}

# allow for interaction to investigate why loop stopped
$command->interact;

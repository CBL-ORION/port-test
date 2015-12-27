#!/usr/bin/env perl

use strict;
use warnings;

use Expect;

my $command = Expect->spawn("matlab", qw(-nosplash -nodesktop -nojvm))
	or die "Couldn't start program: $!\n";

say $command "otrace('test')";

$command->debug( 2 );

my $it = 0;
while ( $command->expect(undef, '>>' ) ) {
	say $command "dump_state, dbcont";
	$it++;
	last if $it > 5;
}

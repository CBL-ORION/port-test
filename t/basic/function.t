use Test::Most;

use strict;
use warnings;

use ORION;

if(not ORION->orionmatdir->exists) {
	plan skip_all => 'No MATLAB code available';
}

plan tests => 1;

my $c_functions = ORION->c_functions;
#use DDP  { class => { expand => 'all' } }; p $c_functions ;

my $m_functions = ORION->matlab_functions;
use DDP  { class => { expand => 'all' } }; p $m_functions ;

ok(1);

done_testing;

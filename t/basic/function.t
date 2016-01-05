use Test::Most;

use ORION;

if(not ORION->orionmatdir->exists) {
	plan skip_all => 'No MATLAB code available';
}

plan tests => 1;

my $c_functions = ORION->c_functions;
#use DDP  { class => { expand => 'all' } }; p $c_functions ;

my $m_functins = ORION->matlab_functions;

ok(1);

done_testing;

use Test::Most;

use ORION;

if(not ORION->orionmatdir->exists) {
	plan skip_all => 'No MATLAB code available';
}

plan tests => 1;

ORION->c_functions;

ORION->matlab_functions;

done_testing;

use Test::More;

use PDL;
use ORION;
use Inline C => 'DATA',
	ENABLE => AUTOWRAP =>
	with => ['ORION'],
	;

my $n_got = get_sequence();

ok( all($n_got == sequence(3, 4, 5)), 'PDL has correct data dimensions and contents' );

ok( expected_ndarray3($n_got), 'expected round-trip back to ndarray3' );

__DATA__
__C__

#include "ndarray/ndarray3.h"

ndarray3* get_sequence() {
	ndarray3* n = ndarray3_new(3, 4, 5);

	/* fill in order */
	float idx = 0;
	for( int i = 0; i < ndarray3_elems(n); i++, idx++) {
		n->p[i] = idx;
	}

	n->has_spacing = true;

	n->spacing[0] = 2;
	n->spacing[1] = 3;
	n->spacing[2] = 5;

	return n;
}


bool expected_ndarray3(ndarray3* n) {
	bool expect = true;

	expect &= 3 == n->sz[0];
	expect &= 4 == n->sz[1];
	expect &= 5 == n->sz[2];

	float idx = 0;
	for( int i = 0; expect && i < ndarray3_elems(n); i++, idx++) {
		expect &= idx == n->p[i];
	}

	expect &= n->has_spacing;

	expect &= 2 == n->spacing[0];
	expect &= 3 == n->spacing[1];
	expect &= 5 == n->spacing[2];

	return expect;
}

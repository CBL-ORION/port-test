package ORION::Types;

use v5.16;
use strict;
use warnings;

use PDL;

sub coerce_type {
	my ($class, $type, $data) = @_;
	given( $type->unqualified_type ) {
		when('int') { long($data)->squeeze }
		when('float') { float($data)->squeeze }
		when('ndarray3 *') { float($data) }
	}
}


1;

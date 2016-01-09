package ORION::Types;

use v5.14;
use strict;
use warnings;

use PDL;

sub coerce_type {
	my ($class, $type, $data) = @_;
	given( $type->unqualified_type ) {
		when('size_t') { long($data)->squeeze }
		when('int') { long($data)->squeeze }
		when('float') { float($data)->squeeze }
		when('ndarray3 *') { float($data) }

		when('orion_Makefilter_flag') {
			# we need to subtract one because the C value is 0-based, not 1-based
			long($data)->squeeze - 1;
		}
		default { die "Do not know how to handle C type $_"; }
	}
}


1;

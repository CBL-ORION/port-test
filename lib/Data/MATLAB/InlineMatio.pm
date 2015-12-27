package Data::MATLAB::InlineMatio;

use strict;
use warnings;

sub Inline {
	return unless $_[-1]  eq 'C';
	return {
		INC => `pkg-config --cflags matio`,
		LIBS => `pkg-config --libs matio`,
	};
}

1;

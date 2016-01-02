package Data::MATLAB::InlineMatio;

use strict;
use warnings;
use Capture::Tiny qw(:all);

sub Inline {
	return unless $_[-1]  eq 'C';
	my ($stdout, $stderr, $exit) = capture {
		system(qw(pkg-config --cflags matio));
	};
	if( $exit ) {
		die "Error configuring libmatio: $stderr";
	}
	return {
		INC => `pkg-config --cflags matio`,
		LIBS => `pkg-config --libs matio`,
	};
}

1;

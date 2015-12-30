package ORION;

use strict;
use warnings;

use Path::Tiny;
use Hash::Merge;

sub basedir {
	my $file = path(__FILE__)->absolute;
	my $lib_dir = $file->parent;
	$lib_dir = $lib_dir->parent until $lib_dir->basename eq 'lib';
	my $base_dir = $lib_dir->parent;
}

sub oriondir {
	my $base_dir = basedir();
	$base_dir->child( qw{ orion });
}

sub Inline {
	return unless $_[-1]  eq 'C';

	# get the PDL config because it is needed for typemap
	my $pdl_config = PDL->Inline('C');

	# make each value an arrayref so that the arrayrefs are concatenated
	# when merging
	my $config = {
		INC => ["-I@{[ oriondir()->child('lib') ]}"],
		LIBS => [ "-L@{[ oriondir()->child( qw{.build .lib} ) ]} -lorion" ],
		TYPEMAPS => [ "@{[ path(__FILE__)->absolute->parent->child( qw{ORION typemap} ) ]}" ],
	};

	my $merged_config = Hash::Merge::merge($config, $pdl_config);
	# the INC value must be a scalar so join array
	$merged_config->{INC} = join " ", @{ $merged_config->{INC} };

	return $merged_config;
}


1;

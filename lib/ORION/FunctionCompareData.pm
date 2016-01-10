package ORION::FunctionCompareData;

use strict;
use warnings;

use ORION::Compare;

our $MAPPING = {
	Makefilter => {
		param_map => {
			'n' => 'hdaf_approx_degree',
			'k' => 'scale_factor',
		},
		compare => \&ORION::Compare::compare_volume_histogram,
	},
	hdaf => {
		param_map => {
			'n' => 'hdaf_approx_degree',
			'c_nk' => 'scaling_constant',
		},
	},
};

1;

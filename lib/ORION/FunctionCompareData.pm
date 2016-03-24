package ORION::FunctionCompareData;

use strict;
use warnings;

use Modern::Perl;
use ORION::Compare;
use Path::Tiny;

sub file_paths_map_to_vol {
	my ($fs) = @_;
	my $vol_path = path( $fs->input->{file_path}, "@{[ $fs->input->{file_name} ]}.mhd" );
	my $vol = ORION::orion_read_mhd( $vol_path );
	{ vol => $vol };
}

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
	ORION3_Dendrites => {
		param_map => {
			p => 'param',
		},
		inject => \&file_paths_map_to_vol,
	},
	settingDefaultParameters => {
		param_map => {
			p => 'param',
		},
	},
	getFeatures => {
		param_map => {
			p => 'param',
		},
		inject => \&file_paths_map_to_vol,
	},
	multiscaleLaplacianFilter => {
		param_map => {
			Lap => 'laplacian_scales',
		},
		inject => sub {
			my $p = file_paths_map_to_vol(@_);
			$p->{input_volume} = delete $p->{vol};
			$p;
		},
	},
};

1;

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
	computeFeatures => {
		inject => sub {
			my ($fs) = @_;
			my $map = {};
			my $vol_map = file_paths_map_to_vol($fs);
			$map = merge( $map, $vol_map );

			# sigma,apply_log,file_name_scales
			my $param_data = {
				sigma => $fs->input->{sigma},
				apply_log => $fs->input->{apply_log},
			};
			my $param = ORION::Types->coerce_type(
				ORION::C::Type->new( decl => 'orion_segmentation_param *' ),
				$param_data,
			);

			$map = merge( $map, { param => $param } );

			return $map;
		}
	},
	getFeatures => {
		param_map => {
			p => 'param',
		},
		inject => \&file_paths_map_to_vol,
	},
	readNegativeSamples => {
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
	computeEigenvaluesGaussianFilter => {
		inject => sub {
			my $p = file_paths_map_to_vol(@_);
			$p->{input_volume} = delete $p->{vol};

			my $method;
			my $method_enum;
			$method_enum->{EIG_FEAT_METHOD_SORT_SATO} = 1;
			$method_enum->{EIG_FEAT_METHOD_SORT_FRANGI} = 2;
			$method_enum->{EIG_FEAT_METHOD_SINGLE_VALUE} = 3;
			given( $p->{sorting} ) {
				when('FRANGI')          { $method = $method_enum->{EIG_FEAT_METHOD_SORT_FRANGI} }
				when('SATO')            { $method = $method_enum->{EIG_FEAT_METHOD_SORT_SATO} }
				when('ORION1_Features') { $method = $method_enum->{EIG_FEAT_METHOD_SINGLE_VALUE} }
			}

			$p->{method} = $method;

			$p;
		},
	},
};

1;

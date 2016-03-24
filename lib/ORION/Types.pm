package ORION::Types;

use v5.14;
use strict;
use warnings;

use Modern::Perl;
use PDL;
use Log::Log4perl qw(:easy);

sub coerce_type {
	my ($class, $type, $data) = @_;
	if( $type->is_ptr and not defined $data ) {
		LOGWARN("Data is not defined (type: @{[ $type->unqualified_type ]})");
		return undef;
	}
	given( $type->unqualified_type ) {
		when('size_t') { long($data)->squeeze }
		when('int') { long($data)->squeeze }
		when('float') { float($data)->squeeze }
		when('ndarray3 *') { float($data) }
		when('array_float *') { float($data)->squeeze }

		when('orion_Makefilter_flag') {
			# we need to subtract one because the C value is 0-based, not 1-based
			long($data)->squeeze - 1;
		}
		when('orion_segmentation_param *') {
			$data = $data->[0];
			my $s = Inline::Struct::orion_segmentation_param->new();
			$s->scales( $data->{sigma}->float->squeeze );
			$s->multiscale( $s->scales->nelem > 1 );
			$s->number_of_stacks( $data->{n_stacks}->indx->sclr  );

			$s->ORION::orion_segmentation_param_set_training(
				$data->{training}->squeeze
			) if exists $data->{training};

			$s->ORION::orion_segmentation_param_set_threshold(
				$data->{threshold}->squeeze
			) if exists $data->{threshold};

			$s->ORION::orion_segmentation_param_set_percentage_threshold_intensity(
				$data->{percentage_threshold_intensity}->squeeze
			) if exists $data->{percentage_threshold_intensity};

			$s->ORION::orion_segmentation_param_set_apply_log(
				$data->{apply_log}
			) if exists $data->{apply_log};

			$s->ORION::orion_segmentation_param_set_release(
				$data->{release}
			) if exists $data->{release};

			$s->ORION::orion_segmentation_param_set_min_conn_comp_to_remove(
				$data->{min_c}->float->sclr
			) if exists $data->{min_c};

			$s->ORION::orion_segmentation_param_set_bins(
				$data->{bins}->float->sclr
			) if exists $data->{bins};

			$s;
		}
		default {
			require Carp::REPL; Carp::REPL->import('repl'); repl();#DEBUG
			die "Do not know how to handle C type $_";
		}
	}
}


1;

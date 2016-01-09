package ORION::Compare;

use strict;
use warnings;

use v5.14;
use PDL;
use Statistics::NiceR;

sub compare_volume_inf_norm {
	my %args = @_;
	my ($expected, $got, $tol) = (
		$args{expected},
		$args{got},
		$args{tol},
	);

	my $diff = abs($expected - $got);
	$diff->max;
}

sub volume_histogram_uniq {
	my ($volume) = @_;
	my $uniq = $volume->flat->uniq;
	my $count = $uniq->zeroes;
	PDL::indadd(1, PDL::vsearch_match( $volume, $uniq ), $count );
	($uniq, $count);
}

sub volume_histogram_bin_largest_dim {
	my ($volume) = @_;
	my ($min, $max) = $volume->minmax;
	my $bins = $volume->shape->max;
	my ($val, $count) = hist( $volume->flat, $min, $max, ($max-$min)/$bins );
	($val, $count);
}

sub histogram_similarity_intersection {
	# Given two histograms $a$ and $b$ with n bins each,
	# the intersection is
	#    K_{\cap}(a,b) = \sum_i^n min( a_i, b_i )
	#
	# Note: This is also equivalent to
	#    K_{\cap}(a,b) = \frac{1}{2} \sum_i^n ( a_i + b_i - \abs{a_i - b_i} )

	my ($ha, $hb) = @_;

	$ha->cat($hb)->xchg(0,1)->minimum->sum / $ha->sum;
}

sub histogram_similarity_emd {
	my ($ha, $hb) = @_;
	# TODO calculate the earth mover's distance between the histograms
	state $r;
	if( not defined $r ) {
		$r = Statistics::NiceR->new;
		$r->library('emdist');
	}

	#$r->emd($ha, $hb);
}

sub histogram_similarity_on_bin_centres {
	my ($ha_v, $hb_v, $tol) = @_;
	sum(abs($ha_v -$hb_v) < $tol)/$hb_v->nelem;
}

sub compare_volume_histogram {
	my %args = @_;
	my ($expected, $got, $tol) = (
		$args{expected},
		$args{got},
		$args{tol},
	);

	$tol //= 1e-10;

	my ($e_v, $e_c) = volume_histogram_bin_largest_dim($expected->double);
	my ($g_v, $g_c) = volume_histogram_bin_largest_dim($got->double);

	my $sim = histogram_similarity_intersection($e_c, $g_c);
	$sim;
}


1;

#!/usr/bin/env perl

use strict;
use warnings;

use v5.16;
use lib 'lib';
use PDL;
use Data::MATLAB;
use ORION;

#use Inline Config =>
	#enable => force_build =>
	#enable => build_noisy =>
	#disable => clean_after_build =>;

use Inline C => 'DATA',
	ENABLE => AUTOWRAP =>
	with => ['ORION'],
	;

my $p = Data::MATLAB->read_data( '../orion/test.mat.v7' );
use DDP; p $p;

my $SZ = 5;
my $factor = 0.25;
my $nd = ndcoords(float, $SZ-1,$SZ,$SZ+1);
#my $q = orion_hdaf(3, 5, sequence(float, 5,5,5));
my $q = orion_hdaf(3, 5, (( 0.25* $nd)**2)->sumover->sqrt->float );
use DDP; p $q;

__DATA__
__C__

#include "ndarray/ndarray3.h"
/*#include "kitchen-sink/01_Segmentation/dendrites_main/DetectTrainingSet/IsotropicFilter/hdaf.h"*/

extern ndarray3* orion_hdaf(
		int hdaf_approx_degree,
		float scaling_constant,
		ndarray3* x);

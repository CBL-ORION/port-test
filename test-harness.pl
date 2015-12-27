#!/usr/bin/env perl

use strict;
use warnings;

use lib 'lib';
use PDL;
use Data::MATLAB;

my $p = Data::MATLAB::show_variables( '../orion/test.mat.v7' );

#use Data::Dumper; print Dumper($p);
use DDP; p $p;


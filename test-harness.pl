#!/usr/bin/env perl

use strict;
use warnings;

use lib 'lib';
use PDL;
use Data::MATLAB;

my $p = Data::MATLAB->read_data( '../orion/test.mat.v7' );

use DDP; p $p;

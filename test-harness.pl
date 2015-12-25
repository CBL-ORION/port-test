#!/usr/bin/env perl

use strict;
use warnings;

use PDL;
use Data::MATFile qw/read_matfile/;;
use PDL::IO::Matlab;
use PDL::IO::HDF5;


my $mat_hdf5 =  PDL::IO::HDF5->new('../orion/test.mat.v7.3');
use DDP; p $mat_hdf5->attrGet("MATLAB_fields");


#my @pdlsv7 =  matlab_read('../orion/test.mat.v7');
#my @pdlsv73 =  matlab_read('../orion/test.mat.v7.3');
#use DDP; p @pdlsv73;

#my $matfilev7 = read_matfile ('../orion/test.mat.v7');
#use DDP; p $matfilev7;
#my $matfilev73 = read_matfile ('../orion/test.mat.v7.3');

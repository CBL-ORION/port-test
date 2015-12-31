package ORION::FunctionState;

use Moo;

has [ qw(matlab_input_args c_input_args) ] => ( is => 'rw' );

1;

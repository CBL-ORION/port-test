package ORION::Role::FunctionRole;

use Moo::Role;
use Types::Standard -types;

requires 'name', 'params', 'language';

has language => ( is => 'ro', isa => Str );

1;

package ORION;

use strict;
use warnings;

use PDL;
use Path::Tiny;
use Hash::Merge;
use Path::Iterator::Rule;
use Parse::RecDescent;
use Data::MATLAB;
use ORION::C::Function;
use ORION::MATLAB::Function;
use ORION::FunctionCompare;
use List::UtilsBy qw(sort_by);
use List::AllUtils;
use Memoize;
use Log::Log4perl qw(:easy);
use Config;

use Inline;
use Inline::Struct;
use Inline::Filters;

sub import {
	_bind_c_functions();
	#_check_typemap_for_unbound_types();
	memoize('ORION::c_functions');
	memoize('ORION::matlab_functions');
}

sub _check_typemap_for_unbound_types {
	require ExtUtils::Typemaps;

	my $c_func = ORION->c_functions;
	my $typemap = ExtUtils::Typemaps->new;

	my @typemap_files;
	push @typemap_files, path( $Config::Config{installprivlib}, "ExtUtils", "typemap" );
	push @typemap_files, @{ ORION->Inline('C')->{TYPEMAPS} };

	for my $tm (@typemap_files) {
		my $tm_clean = path($tm)->slurp_utf8;
		if( $tm =~ /PDL/ ) {
			$tm_clean =~ s/^\Qpdl*\E.*//m;
			$tm_clean =~ s/^\Qpdl_trans*\E.*//m;
			$tm_clean =~ s/^\Qfloat\E.*//m;
		}
		my $new_tm = ExtUtils::Typemaps->new( string => $tm_clean );
		$typemap->merge( typemap => $new_tm );
	}

	my %ctypes = map { $_ => 1 } $typemap->list_mapped_ctypes;
	my %unmapped_ctypes;

	for my $f (@$c_func) {
		my @types;
		push @types, map { $_->type->decl } @{ $f->params };
		push @types, $f->return_type->decl;
		for my $type (@types) {
			unless(exists $ctypes{$type}) {
				push @{ $unmapped_ctypes{$type} }, $f->name;
			}
		}
	}
	delete $unmapped_ctypes{'...'}; # not an actual type
	delete $unmapped_ctypes{'void'}; # not an actual type

	use DDP; p %unmapped_ctypes;

	[ keys %unmapped_ctypes ];
}

sub get_function_names_from_function_state_data {
	my $debug_trace_dir = ORION->function_state_dir;
	my $mat_file_rule = Path::Iterator::Rule->new
		->file->name( qr/F_BEGIN.*\.mat$/ );
	my $mat_file_iter = $mat_file_rule->iter( $debug_trace_dir );

	my $function_names;
	INFO "Reading list of function names from the function state data directory";
	while( defined( my $mat_file = $mat_file_iter->() ) ) {
		# the first part of the filename is the function name
		my $f_name = ( path($mat_file)->basename =~ /^([^.]+)/ )[0];
		$function_names->{$f_name} = 1;
	}
	return [ keys %$function_names ];
}

sub build_function_comparisons {
	my $matlab_functions_by_name = {
		map { ( $_->name => $_ ) }
		@{ ORION->matlab_functions } };
	my $c_functions_by_name = {
		map { ( $_->name => $_ ) }
		@{ ORION->c_functions } };

	my $function_names = ORION->get_function_names_from_function_state_data;

	my $function_compare_by_name = {};
	my $m_func_not_matched;
	for my $m_func_name (@$function_names) {
		my $c_func_name = "orion_$m_func_name";
		if( exists $c_functions_by_name->{$c_func_name} ) {
			$function_compare_by_name->{$m_func_name} =
				ORION::FunctionCompare->new(
					matlab_function => $matlab_functions_by_name->{$m_func_name},
					c_function => $c_functions_by_name->{$c_func_name},
				);
		} else {
			push @$m_func_not_matched, $m_func_name;
		}
	}

	# TODO need to examine $m_func_not_matched
	LOGWARN "There are @{[ scalar @$m_func_not_matched ]} MATLAB functions that do not have corresponding C functions";

	$function_compare_by_name;
}

sub _bind_c_functions {
	my @c_funcs = sort_by { $_->name } @{ ORION->c_functions };
	my $protos = join "\n", map { $_->prototype } @c_funcs;
	my $headers = <<'C';
#include <assert.h>
#include <complex.h>
#include <errno.h>
#include <float.h>
#include <math.h>
#include <stdarg.h>
#include <stdbool.h>
#include <stddef.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <time.h>

typedef bool DONE_WITH_STDINC;

#include "ndarray/ndarray3.h"
#include "ndarray/ndarray3_complex.h"

#include "container/array.h"
#include "container/vector.h"

#include "param/segmentation.h"
#include "param/io.h"
#include "param/orion3.h"

#include "io/path/path.h"
#include "io/format/mhd.h"

#include "kitchen-sink/01_Segmentation/dendrites_main/ExtractFeatures/computeEigenvaluesGaussianFilter.h"
#include "kitchen-sink/01_Segmentation/dendrites_main/DetectTrainingSet/IsotropicFilter/Makefilter.h"
#include "kitchen-sink/01_Segmentation/dendrites_main/DetectTrainingSet/multiscaleLaplacianFilter.h"
#include "kitchen-sink/01_Segmentation/dendrites_main/DetectTrainingSet/IsotropicFilter/hdaf.h"
#include "kitchen-sink/01_Segmentation/dendrites_main/ExtractFeatures/getFeatures.h"
#include "kitchen-sink/01_Segmentation/dendrites_main/settingDefaultParameters.h"
#include "kitchen-sink/01_Segmentation/dendrites_main/DetectTrainingSet/readNegativeSamples.h"
#include "kitchen-sink/01_Segmentation/dendrites_main/ORION3_Dendrites.h"
#include "kitchen-sink/01_Segmentation/dendrites_main/ExtractFeatures/computeFeatures.h"

#include "orion_util.c"

C

	Inline->bind( C => "$headers\n\n",#"$protos",
		FILTERS => [
			'Preprocess',
			sub {
				# remove bits before orion library
				shift =~ s|\A.*DONE_WITH_STDINC.*?$||gsmr;
			},
			sub {
				# remove preprocessor output
				shift =~ s|^#.*$||gmr;
			},
			#sub { use DDP; my $c = shift; p $c; $c },
			],
		enable => structs =>,
		ENABLE => AUTOWRAP =>
		with => [ 'ORION' ] );
}

sub basedir {
	my $file = path(__FILE__)->absolute;
	my $lib_dir = $file->parent;
	$lib_dir = $lib_dir->parent until $lib_dir->basename eq 'lib';
	my $base_dir = $lib_dir->parent;
}

sub oriondir {
	my $base_dir = basedir();
	$base_dir->child( qw{ orion });
}

sub orionmatdir {
	my $base_dir = basedir();
	$base_dir->child( qw{ external orionmat });
}

sub matlabsrcdir {
	my $matlab_source = ORION->basedir->child(qw(src matlab));
}

sub datadir {
	my $base_dir = basedir();
	$base_dir->child('data');
}

sub function_state_dir {
	my $debug_trace_dir = ORION->datadir->child(qw(debug-trace));
}

sub stack_traces_path {
	my $stack_trace_path = ORION->function_state_dir->child('stack-traces.yml');
}

sub call_graph_path {
	my $stack_trace_path = ORION->function_state_dir->child('call-graph.yml');
}

sub diff_path {
	my $stack_trace_path = ORION->function_state_dir->child('diff.yml');
}

sub Inline {
	return unless $_[-1]  eq 'C';

	# get the PDL config because it is needed for typemap
	my $pdl_config = PDL->Inline('C');

	# make each value an arrayref so that the arrayrefs are concatenated
	# when merging
	my $config = {
		AUTO_INCLUDE => [ <<C ],
C
		INC => [
			"-std=c99",
			"-I@{[ oriondir()->child('lib') ]}",
			"-I@{[ oriondir()->child('lib', 'param') ]}",
			"-I@{[ path(__FILE__)->absolute->parent->child( qw{ORION} ) ]}",
		],
		LIBS => [ "-L@{[ oriondir()->child( qw{.build .lib} ) ]} -lorion" ],
		TYPEMAPS => [ "@{[ path(__FILE__)->absolute->parent->child( qw{ORION typemap} ) ]}" ],
	};

	my $merged_config = Hash::Merge::merge($config, $pdl_config);
	# the INC value must be a scalar so join array
	$merged_config->{INC} = join " ", @{ $merged_config->{INC} };
	$merged_config->{AUTO_INCLUDE} = join "\n", reverse @{ $merged_config->{AUTO_INCLUDE} };

	return $merged_config;
}

sub c_functions {
	# get all the .h files under lib/
	my $c_project_lib = ORION->oriondir->child('lib');
	my $header_file_rule = Path::Iterator::Rule->new
		->file->name( qr/\.h$/ );
	my $header_file_iter = $header_file_rule->iter( $c_project_lib );

	my $functions;
	INFO "Getting a list of C functions for project in $c_project_lib";
	while( defined( my $file = $header_file_iter->() ) ) {
		my $code = path($file)->slurp_utf8;
		my $parser = Parse::RecDescent->new(c_grammar());
		$parser->{data}{AUTOWRAP} = 1;
		$parser->{data}{file} = $file;
		$parser->code( $code ) or die "could not parse file $file";

		# create C function objects
		push @{$functions}, @{
			ORION::C::Function->new_functions_from_parser_data( $parser->{data} );
		}
	}
	return $functions;
}

sub matlab_functions {
	# get all the .h files under lib/
	my $matlab_func_mat_file = ORION->datadir->child('matlab_func.mat');

	my $matlab_source = ORION->matlabsrcdir;
	my $project = ORION->orionmatdir;

	INFO "Getting a list of MATLAB functions for project in $project";
	unless( -r $matlab_func_mat_file ) {
		my $EXEC = join ",", (
			"addpath('$matlab_source')",
			"parse_project_matlab_funcs('$project', '$matlab_func_mat_file')",
			"exit"
		);
		system( qw(matlab -nodesktop -nodisplay -nosplash),
			'-r', $EXEC );
	} else {
		INFO "Using cache in $matlab_func_mat_file";
	}
	my $data = Data::MATLAB->read_data( $matlab_func_mat_file );
	return [ map {
		ORION::MATLAB::Function->new_from_parser_data($_)
	} @{ $data->{data}[0]{functions} } ];
}

sub c_grammar {
    <<'END';

code:   part(s)
        {
         return 1;
        }

part:   comment
      | function_definition
        {
         my $function = $item[1][0];
         $return = 1, last if $thisparser->{data}{done}{$function}++;
         push @{$thisparser->{data}{functions}}, $function;
         $thisparser->{data}{function}{$function}{return_type} =
             $item[1][1];
         $thisparser->{data}{function}{$function}{arg_types} =
             [map {ref $_ ? $_->[0] : '...'} @{$item[1][2]}];
         $thisparser->{data}{function}{$function}{arg_names} =
             [map {ref $_ ? $_->[1] : '...'} @{$item[1][2]}];
        }
      | function_declaration
        {
         $return = 1, last unless $thisparser->{data}{AUTOWRAP};
         my $function = $item[1][0];
         $return = 1, last if $thisparser->{data}{done}{$function}++;
         my $dummy = 'arg1';
         push @{$thisparser->{data}{functions}}, $function;
         $thisparser->{data}{function}{$function}{return_type} =
             $item[1][1];
         $thisparser->{data}{function}{$function}{arg_types} =
             [map {ref $_ ? $_->[0] : '...'} @{$item[1][2]}];
         $thisparser->{data}{function}{$function}{arg_names} =
             [map {ref $_ ? ($_->[1] || $dummy++) : '...'} @{$item[1][2]}];
        }
      | anything_else

comment:
        m{\s* // [^\n]* \n }x
      | m{\s* /\* (?:[^*]+|\*(?!/))* \*/  ([ \t]*)? }x

function_definition:
        rtype IDENTIFIER '(' <leftop: arg ',' arg>(s?) ')' '{'
        {
         [@item[2,1], $item[4]]
        }

function_declaration:
        rtype IDENTIFIER '(' <leftop: arg_decl ',' arg_decl>(s?) ')' ';'
        {
         [@item[2,1], $item[4]]
        }

rtype:  rtype1 | rtype2

rtype1: modifier(s?) TYPE star(s?)
        {
         $return = $item[2];
         $return = join ' ',@{$item[1]},$return
           if @{$item[1]} and $item[1][0] ne 'extern';
         $return .= join '',' ',@{$item[3]} if @{$item[3]};
         #return undef unless (defined $thisparser->{data}{typeconv}
                                                   #{valid_rtypes}{$return});
        }

rtype2: modifier(s) star(s?)
        {
         $return = join ' ',@{$item[1]};
         $return .= join '',' ',@{$item[2]} if @{$item[2]};
         #return undef unless (defined $thisparser->{data}{typeconv}
                                                   #{valid_rtypes}{$return});
        }

arg:    type IDENTIFIER {[@item[1,2]]}
      | '...'

arg_decl:
        type IDENTIFIER(s?) {[$item[1], $item[2][0] || '']}
      | '...'

type:   type1 | type2

type1:  modifier(s?) TYPE star(s?)
        {
         $return = $item[2];
         $return = join ' ',@{$item[1]},$return if @{$item[1]};
         $return .= join '',' ',@{$item[3]} if @{$item[3]};
         #return undef unless (defined $thisparser->{data}{typeconv}
                                                   #{valid_types}{$return});
        }

type2:  modifier(s) star(s?)
        {
         $return = join ' ',@{$item[1]};
         $return .= join '',' ',@{$item[2]} if @{$item[2]};
         #return undef unless (defined $thisparser->{data}{typeconv}
                                                   #{valid_types}{$return});
        }

modifier:
        'unsigned' | 'long' | 'extern' | 'const'

star:   '*'

IDENTIFIER:
        /\w+/

TYPE:   /\w+/

anything_else:
        /.*/

END
}

1;

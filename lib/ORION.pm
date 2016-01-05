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

sub Inline {
	return unless $_[-1]  eq 'C';

	# get the PDL config because it is needed for typemap
	my $pdl_config = PDL->Inline('C');

	# make each value an arrayref so that the arrayrefs are concatenated
	# when merging
	my $config = {
		AUTO_INCLUDE => [ <<C ],
#include "orion_util.c"
C
		INC => [
			"-std=c99",
			"-I@{[ oriondir()->child('lib') ]}",
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
	my $header_file_rule = Path::Iterator::Rule->new
		->file->name( qr/\.h$/ );
	my $header_file_iter = $header_file_rule->iter( ORION->oriondir->child('lib') );
	my $functions;
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

	unless( -r $matlab_func_mat_file ) {
		my $EXEC = join ",", (
			"addpath('$matlab_source')",
			"parse_project_matlab_funcs('$project', '$matlab_func_mat_file')",
			"exit"
		);
		system( qw(matlab -nodesktop -nodisplay -nosplash),
			'-r', $EXEC );
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

#!/usr/bin/env perl

use strict;
use warnings;

use PDL;

use Inline C => 'DATA',
	INC => `pkg-config --cflags matio`,
	LIBS => `pkg-config --libs matio`,;

show_variables( '../orion/test.mat.v7' );

__END__
__C__
#include <stdlib.h>
#include <stdio.h>
#include "matio.h"

const char* matio_class_to_char( enum matio_classes ct );

SV* show_variables( char* filename ) {
	mat_t *matfp; /* used to open file r/o */
	matvar_t *matvar; /* used to iterate over variables */

	matfp = Mat_Open(filename, MAT_ACC_RDONLY);
	if ( NULL == matfp ) {
		croak("Error opening MAT file \"%s\"!\n", filename);
	}

	while ( (matvar = Mat_VarReadNextInfo(matfp)) != NULL ) {
		printf("name: %s : class: %s\n",
			matvar->name,
			matio_class_to_char(matvar->class_type));
		Mat_VarFree(matvar);
		matvar = NULL;
	}


	Mat_Close(matfp);

	return NULL;
}

SV* process_matvar( matvar_t* data ) {
	/* switch over `enum matio_classes` */
	switch( data->class_type ) {
		case MAT_C_EMPTY: break;
		case MAT_C_CELL: break;
		case MAT_C_STRUCT: break;
		case MAT_C_OBJECT: break;
		case MAT_C_CHAR: break;
		case MAT_C_SPARSE: break;
		case MAT_C_DOUBLE: break;
		case MAT_C_SINGLE: break;
		case MAT_C_INT8: break;
		case MAT_C_UINT8: break;
		case MAT_C_INT16: break;
		case MAT_C_UINT16: break;
		case MAT_C_INT32: break;
		case MAT_C_UINT32: break;
		case MAT_C_INT64: break;
		case MAT_C_UINT64: break;
		case MAT_C_FUNCTION: break;
	}
	return NULL;
}

const char* matio_class_to_char( enum matio_classes ct ) {
	switch( ct ) {
		case MAT_C_EMPTY: return "MAT_C_EMPTY";
		case MAT_C_CELL: return "MAT_C_CELL";
		case MAT_C_STRUCT: return "MAT_C_STRUCT";
		case MAT_C_OBJECT: return "MAT_C_OBJECT";
		case MAT_C_CHAR: return "MAT_C_CHAR";
		case MAT_C_SPARSE: return "MAT_C_SPARSE";
		case MAT_C_DOUBLE: return "MAT_C_DOUBLE";
		case MAT_C_SINGLE: return "MAT_C_SINGLE";
		case MAT_C_INT8: return "MAT_C_INT8";
		case MAT_C_UINT8: return "MAT_C_UINT8";
		case MAT_C_INT16: return "MAT_C_INT16";
		case MAT_C_UINT16: return "MAT_C_UINT16";
		case MAT_C_INT32: return "MAT_C_INT32";
		case MAT_C_UINT32: return "MAT_C_UINT32";
		case MAT_C_INT64: return "MAT_C_INT64";
		case MAT_C_UINT64: return "MAT_C_UINT64";
		case MAT_C_FUNCTION: return "MAT_C_FUNCTION";
	}

	croak("Invalid matio class: %d", ct);

	return NULL; /* not reached */
}

SV* process_unimplemented(matvar_t* data) {
	croak( "Unimplmented conversion for: name: %s class: %s",
		data->name,
		matio_class_to_char(data->class_type) );
	return NULL; /* not reached */
}

SV* process_mat_t_cell(matvar_t* data) {
	return NULL;
}

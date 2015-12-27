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
#include <stdbool.h>
#include "matio.h"

/* function prototypes */
const char* matio_class_to_char( enum matio_classes ct );
inline const char* matio_bool_to_char(bool p);
void matio_dump_info( matvar_t* data );
SV* process_mat_t_cell(matvar_t* data);
SV* process_unimplemented(matvar_t* data);
size_t matio_nelems(matvar_t* data);
SV* process_matvar( matvar_t* data );

SV* show_variables( char* filename ) {
	mat_t *matfp; /* used to open file r/o */
	matvar_t *matvar; /* used to iterate over variables */

	matfp = Mat_Open(filename, MAT_ACC_RDONLY);
	if ( NULL == matfp ) {
		croak("Error opening MAT file \"%s\"!\n", filename);
	}

	while ( (matvar = Mat_VarReadNextInfo(matfp)) != NULL ) {
		matio_dump_info(matvar);
		process_matvar( matvar );
		Mat_VarFree(matvar);
		matvar = NULL;
	}


	Mat_Close(matfp);

	return NULL;
}

SV* process_matvar( matvar_t* data ) {
	/* switch over `enum matio_classes` */
	switch( data->class_type ) {
		case MAT_C_EMPTY:     return process_unimplemented(data);
		case MAT_C_CELL:      return process_mat_t_cell(data);
		case MAT_C_STRUCT:    return process_unimplemented(data);
		case MAT_C_OBJECT:    return process_unimplemented(data);
		case MAT_C_CHAR:      return process_unimplemented(data);
		case MAT_C_SPARSE:    return process_unimplemented(data);
		case MAT_C_DOUBLE:    return process_unimplemented(data);
		case MAT_C_SINGLE:    return process_unimplemented(data);
		case MAT_C_INT8:      return process_unimplemented(data);
		case MAT_C_UINT8:     return process_unimplemented(data);
		case MAT_C_INT16:     return process_unimplemented(data);
		case MAT_C_UINT16:    return process_unimplemented(data);
		case MAT_C_INT32:     return process_unimplemented(data);
		case MAT_C_UINT32:    return process_unimplemented(data);
		case MAT_C_INT64:     return process_unimplemented(data);
		case MAT_C_UINT64:    return process_unimplemented(data);
		case MAT_C_FUNCTION:  return process_unimplemented(data);
	}
	return NULL;
}

const char* matio_class_to_char( enum matio_classes ct ) {
	switch( ct ) {
		case MAT_C_EMPTY:     return "MAT_C_EMPTY";
		case MAT_C_CELL:      return "MAT_C_CELL";
		case MAT_C_STRUCT:    return "MAT_C_STRUCT";
		case MAT_C_OBJECT:    return "MAT_C_OBJECT";
		case MAT_C_CHAR:      return "MAT_C_CHAR";
		case MAT_C_SPARSE:    return "MAT_C_SPARSE";
		case MAT_C_DOUBLE:    return "MAT_C_DOUBLE";
		case MAT_C_SINGLE:    return "MAT_C_SINGLE";
		case MAT_C_INT8:      return "MAT_C_INT8";
		case MAT_C_UINT8:     return "MAT_C_UINT8";
		case MAT_C_INT16:     return "MAT_C_INT16";
		case MAT_C_UINT16:    return "MAT_C_UINT16";
		case MAT_C_INT32:     return "MAT_C_INT32";
		case MAT_C_UINT32:    return "MAT_C_UINT32";
		case MAT_C_INT64:     return "MAT_C_INT64";
		case MAT_C_UINT64:    return "MAT_C_UINT64";
		case MAT_C_FUNCTION:  return "MAT_C_FUNCTION";
	}

	croak("Invalid matio class: %d", ct);

	return NULL; /* not reached */
}

SV* process_unimplemented(matvar_t* data) {
	croak( "Unimplemented conversion for: name: %s class: %s",
		data->name,
		matio_class_to_char(data->class_type) );
	return NULL; /* not reached */
}

SV* process_mat_t_cell(matvar_t* data) {
	process_unimplemented(data);

	size_t nelems = matio_nelems(data);
	for( int elem_i = 0; elem_i < nelems; elem_i++ ) {
		matvar_t* data_elem = ((matvar_t**)(data->data))[elem_i];
		process_matvar( data_elem );
	}
	return NULL; /* TODO */
}

size_t matio_nelems(matvar_t* data) {
	size_t nelems = 1;
	for( int rank_i = 0; rank_i < data->rank; rank_i++ ) {
		nelems *= data->dims[rank_i];
	}
	return nelems;
}

void matio_dump_info( matvar_t* data ) {
	fprintf(stderr, "name: %s [class: %s]\n",
		data->name,
		matio_class_to_char(data->class_type));

	/* print the size */
	fprintf(stderr, "\trank: %d", data->rank);
	fprintf(stderr, " dims: [ ");
	for( int rank_i = 0; rank_i < data->rank; rank_i++ ) {
		fprintf(stderr, "%d ", data->dims[rank_i]);
	}
	fprintf(stderr, "]\n");

	fprintf(stderr, "\tis complex?: %s\n",
		matio_bool_to_char((bool)(data->isComplex)));
	fprintf(stderr, "\tis logical?: %s\n",
		matio_bool_to_char((bool)(data->isLogical)));
	fprintf(stderr, "\tis global?: %s\n",
		matio_bool_to_char((bool)(data->isGlobal)));
}

inline const char* matio_bool_to_char(bool p) {
	return p ? "true" : "false";
}

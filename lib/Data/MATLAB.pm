package Data::MATLAB;

use strict;
use warnings;

use Data::MATLAB::InlineMatio;

use Inline C => 'DATA',
	INC => '-std=c99',
	with => ['Data::MATLAB::InlineMatio', 'PDL'];

1;
__DATA__
__C__
#include <stdlib.h>
#include <stdio.h>
#include <string.h>
#include <stdbool.h>
#include "matio.h"

/* Older versions of libmatio do not have the `MAT_C_EMPTY` symbol. Instead of
 * commenting out it entirely in the code below, define it to be a negative
 * value to avoid conflict with other values in the `matio_classes` enum.
 */
#ifndef MAT_C_EMPTY
#define MAT_C_EMPTY -1
#endif /* MAT_C_EMPTY */

/* function prototypes */
const char* matio_class_to_char( enum matio_classes ct );
inline const char* matio_bool_to_char(bool p);
void matio_dump_info( matvar_t* data );
SV* process_mat_t_cell(matvar_t* data);
SV* process_unimplemented(matvar_t* data);
size_t matio_nelems(matvar_t* data);
SV* process_matvar( matvar_t* data );
SV* process_mat_t_struct(matvar_t* data);
SV* process_mat_c_double(matvar_t* data);
SV* process_mat_c_single(matvar_t* data);
SV* process_mat_c_uint8(matvar_t* data);
SV* process_mat_c_uint16(matvar_t* data);
SV* process_mat_c_char(matvar_t* data);

SV* read_data(SV* self, char* filename ) {
	mat_t *matfp; /* used to open file r/o */
	matvar_t *matvar; /* used to iterate over variables */

	matfp = Mat_Open(filename, MAT_ACC_RDONLY);
	if ( NULL == matfp ) {
		croak("Error opening MAT file \"%s\"!\n", filename);
	}

	HV* workspace = newHV();
	SV* ref_workspace;
	while ( (matvar = Mat_VarReadNext(matfp)) != NULL ) {
		char* key = matvar->name;
		SV* val = process_matvar( matvar );
		hv_store(workspace, key, strlen(key), val, 0);
		Mat_VarFree(matvar);
		matvar = NULL;
	}
	ref_workspace = newRV_noinc((SV*)workspace);

	Mat_Close(matfp);

	return ref_workspace;
}

SV* process_matvar( matvar_t* data ) {
	/*[>DEBUG<]matio_dump_info(data);*/
	/* switch over `enum matio_classes` */
	if( data->isComplex ) {
		croak("Do not know how to handle complex data: name: %s class: %s",
			data->name, matio_class_to_char(data->class_type));
	}
	switch( data->class_type ) {
		case MAT_C_EMPTY:     return process_unimplemented(data);
		case MAT_C_CELL:      return process_mat_t_cell(data);
		case MAT_C_STRUCT:    return process_mat_t_struct(data);
		case MAT_C_OBJECT:    return process_unimplemented(data);
		case MAT_C_CHAR:      return process_mat_c_char(data);
		case MAT_C_SPARSE:    return process_unimplemented(data);
		case MAT_C_DOUBLE:    return process_mat_c_double(data);
		case MAT_C_SINGLE:    return process_mat_c_single(data);
		case MAT_C_INT8:      return process_unimplemented(data);
		case MAT_C_UINT8:     return process_mat_c_uint8(data);
		case MAT_C_INT16:     return process_unimplemented(data);
		case MAT_C_UINT16:    return process_mat_c_uint16(data);
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
	AV* av_of_cells;
	SV* ref_av_of_cells;

	av_of_cells = newAV();
	size_t nelems = matio_nelems(data);
	for( int elem_i = 0; elem_i < nelems; elem_i++ ) {
		matvar_t* data_elem = ((matvar_t**)(data->data))[elem_i];
		SV* sv_cell = process_matvar( data_elem );
		av_push(av_of_cells, sv_cell);
	}
	ref_av_of_cells = newRV_noinc((SV*)av_of_cells);

	return ref_av_of_cells;
}

SV* matvar_t_to_pdl(matvar_t* data, int datatype) {
	pdl* p;
	SV* rv;

	p = PDL->pdlnew();
	PDL->setdims(p, data->dims, data->rank);
	p->datatype = datatype;
	PDL->allocdata(p);
	memcpy(p->data, data->data, data->nbytes);

	if( data->isLogical ) {
		HV* p_h;
		if( !p->hdrsv ) {
			p->hdrsv = (SV*)newRV((SV*)newHV());
		}
		p_h = (HV*)SvRV((SV*)(p->hdrsv));

		hv_stores( p_h, "logical", newSViv( !!( data->isLogical ) ));
	}

	/* store in SV */
	rv = newSV(0);
	PDL->SetSV_PDL(rv, p);

	return rv;

}

SV* process_mat_c_double(matvar_t* data) {
	return matvar_t_to_pdl(data, PDL_D);
}

SV* process_mat_c_single(matvar_t* data) {
	return matvar_t_to_pdl(data, PDL_F);
}

SV* process_mat_c_uint8(matvar_t* data) {
	return matvar_t_to_pdl(data, PDL_B);
}

SV* process_mat_c_uint16(matvar_t* data) {
	return matvar_t_to_pdl(data, PDL_US);
}

SV* process_mat_c_char(matvar_t* data) {
	SV* rv;
	if( data->rank == 2 && data->dims[0] == 1 ) {
		/* convert to a string stored in a scalar */
		rv = newSVpv( (char*)(data->data), data->dims[1] );
	} else {
		croak("TODO implement PDL::Char array");
	}

	return rv;
}



SV* process_mat_t_struct(matvar_t* data) {
	size_t nelems = matio_nelems(data);
	size_t nfields = Mat_VarGetNumberOfFields(data);
	char* const* field_names = Mat_VarGetStructFieldnames(data);

	AV* av_of_structs;
	SV* ref_av_of_structs;

	av_of_structs = newAV();
	size_t data_i = 0;
	for( int elem_i = 0; elem_i < nelems; elem_i++ ) {
		HV* hv_struct = newHV();
		for( int field_i = 0; field_i < nfields; field_i++) {
			matvar_t* data_elem = ((matvar_t**)(data->data))[data_i];
			char* key = field_names[field_i];
			SV* val = process_matvar( data_elem );
			hv_store(hv_struct, key, strlen(key), val, 0);
			data_i++;
		}
		av_push(av_of_structs, newRV_noinc((SV*)hv_struct));
	}
	ref_av_of_structs = newRV_noinc((SV*)av_of_structs);
	return ref_av_of_structs;
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
	fprintf(stderr, "\tdata size: %d\n", data->data_size);
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

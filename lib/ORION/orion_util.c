#ifndef PERL_ORION_UTIL_H
#define PERL_ORION_UTIL_H 1

#include "ndarray/ndarray3.h"
#include "container/array.h"
#include "container/vector.h"


ndarray3* pdl_to_ndarray3(SV* arg) {
	ndarray3* var; /* return value */

	/* need to wrap the PDL data field using ndarray3_wrap */
	pdl* p_in = PDL->SvPDLV(arg);

	if( PDL_F != p_in->datatype )
		croak("Can not use typemap! PDL does not contain float data (datatype: %d)", p_in->datatype);
	if( 3 != p_in->ndims )
		croak("Can not use PDL data! The input is not rank 3 (rank: %d)", p_in->ndims);
	var = ndarray3_wrap( (float*)(p_in->data),
		p_in->dims[0],
		p_in->dims[1],
		p_in->dims[2] );
	if( p_in->hdrsv ) {
		HV* p_in_hv = (HV*)SvRV( (SV*)( p_in->hdrsv ) );
		SV** p_in_spacing_sv;
		if( p_in_spacing_sv = hv_fetchs(p_in_hv, "spacing", 0 ) ) {
			AV* p_in_spacing_av = (AV*)SvRV( *p_in_spacing_sv );

			var->has_spacing = true;

			for( int dim_idx = 0; dim_idx < PIXEL_NDIMS; dim_idx++ ) {
				/* NOTE: not checking the result of av_fetch because we
				 * assume spacing is an arrayref of correct length */
				var->spacing[dim_idx] = SvNV(*av_fetch(p_in_spacing_av, dim_idx, 0));
			}
		}
	}

	/* once we are through with the scope, we can free the ndarray3* */
	SAVEDESTRUCTOR(ndarray3_free, var);

	return var;
}

void ndarray3_to_pdl(ndarray3* var, SV* arg) {
	/* need to wrap ndarray3 data field in a PDL structure -> SV* */
	pdl* p_out = PDL->pdlnew();
	PDL->setdims(p_out, var->sz, 3); /* rank 3 */
	p_out->data = var->p; /* point at the ndarray3 data */
	p_out->datasv = newSVuv(PTR2UV(p_out->data)); /* need a datasv so it can be free'd later */
	p_out->datatype = PDL_F; /* using float (pixel_type) for storage */

	/* make sure the core doesn't meddle with your data */
	p_out->state |= PDL_ALLOCATED;

	/* if has_spacing, need to set key in PDL header */
	if( var->has_spacing ) {
		HV* p_out_hv;
		if( !p_out->hdrsv ) {
			p_out->hdrsv = (SV*)newRV((SV*)newHV());
		}

		p_out_hv = (HV*)SvRV((SV*)(p_out->hdrsv));

		AV* spacing_av = (AV*)sv_2mortal((SV*)newAV());
		for( int dim_idx = 0; dim_idx < PIXEL_NDIMS; dim_idx++ ) {
			av_push(spacing_av, newSVnv(  var->spacing[dim_idx]  ) );
		}

		hv_stores( p_out_hv, "spacing", newRV((SV*) spacing_av ));
	}

	PDL->SetSV_PDL(arg,p_out);

	/* set wrap to true and free --- ndarray3* no longer owns data */
	var->wrap = true;
	ndarray3_free(var);
}

array_float* pdl_to_array_float(SV* arg) {
	pdl* p_in = PDL->SvPDLV(arg);

	if( PDL_F != p_in->datatype )
		croak("Can not use typemap! PDL does not contain float data (datatype: %d)", p_in->datatype);
	if( 1 != p_in->ndims )
		croak("Can not use PDL data! The input is not rank 1 (rank: %d)", p_in->ndims);

	size_t len = p_in->dims[0];
	float* data = (float*)(p_in->data);

	array_float* var = array_new_float(len);

	for( int i = 0; i < len; i++ ) {
		array_add_float( var, data[i]);
	}

	SAVEDESTRUCTOR(array_free_float, var);

	return var;
}

void array_float_to_pdl(array_float* var, SV* arg) {
	size_t len = array_length_float(var);
	size_t dim[] = { len };

	pdl* p_out = PDL->pdlnew();
	PDL->setdims(p_out, dim, 1); /* rank 1 */
	p_out->datatype = PDL_F; /* using float (pixel_type) for storage */
	PDL->allocdata(p_out);

	float* data = (float*)(p_out->data);
	for( size_t i = 0; i < len; i++ ) {
		data[i] = array_get_float( var, i );
	}


	PDL->SetSV_PDL(arg,p_out);
}

vector_float* pdl_to_vector_float(SV* arg) {
	pdl* p_in = PDL->SvPDLV(arg);

	if( PDL_F != p_in->datatype )
		croak("Can not use typemap! PDL does not contain float data (datatype: %d)", p_in->datatype);
	if( 1 != p_in->ndims )
		croak("Can not use PDL data! The input is not rank 1 (rank: %d)", p_in->ndims);

	size_t len = p_in->dims[0];
	float* data = (float*)(p_in->data);

	vector_float* var = vector_new_float(len);

	for( int i = 0; i < len; i++ ) {
		vector_add_float( var, data[i]);
	}

	SAVEDESTRUCTOR(vector_free_float, var);

	return var;
}

void vector_float_to_pdl(vector_float* var, SV* arg) {
	size_t len = vector_length_float(var);
	size_t dim[] = { len };

	pdl* p_out = PDL->pdlnew();
	PDL->setdims(p_out, dim, 1); /* rank 1 */
	p_out->datatype = PDL_F; /* using float (pixel_type) for storage */
	PDL->allocdata(p_out);

	float* data = (float*)(p_out->data);
	for( size_t i = 0; i < len; i++ ) {
		data[i] = vector_get_float( var, i );
	}


	PDL->SetSV_PDL(arg,p_out);
}



#endif /* PERL_ORION_UTIL_H */

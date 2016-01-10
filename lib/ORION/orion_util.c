#ifndef PERL_ORION_UTIL_H
#define PERL_ORION_UTIL_H 1

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
	PDL->setdims(p_out, ((ndarray3*)var)->sz, 3); /* rank 3 */
	p_out->data = ((ndarray3*)var)->p; /* point at the ndarray3 data */
	p_out->datasv = newSVuv(PTR2UV(p_out->data)); /* need a datasv so it can be free'd later */
	p_out->datatype = PDL_F; /* using float (pixel_type) for storage */

	/* make sure the core doesn't meddle with your data */
	p_out->state |= PDL_ALLOCATED;

	/* if has_spacing, need to set key in PDL header */
	if( ((ndarray3*)var)->has_spacing ) {
		HV* p_out_hv;
		if( !p_out->hdrsv ) {
			p_out->hdrsv = newRV((SV*)newHV());
		}

		p_out_hv = SvRV((SV*)(p_out->hdrsv));

		AV* spacing_av = (AV*)sv_2mortal((SV*)newAV());
		for( int dim_idx = 0; dim_idx < PIXEL_NDIMS; dim_idx++ ) {
			av_push(spacing_av, newSVnv(  ((ndarray3*)var)->spacing[dim_idx]  ) );
		}

		hv_stores( p_out_hv, "spacing", newRV((SV*) spacing_av ));
	}

	PDL->SetSV_PDL(arg,p_out);

	/* set wrap to true and free --- ndarray3* no longer owns data */
	((ndarray3*)var)->wrap = true;
	ndarray3_free(((ndarray3*)var));
}

#endif /* PERL_ORION_UTIL_H */

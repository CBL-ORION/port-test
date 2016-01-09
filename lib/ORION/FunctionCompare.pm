package ORION::FunctionCompare;

use Moo;

use ORION::FunctionStateFile;
use ORION::Types;
use Log::Log4perl qw(:easy);

use ORION::FunctionCompareData;

has qw(function_state_dir) => ( is => 'ro', required => 1,
	default => sub { ORION->function_state_dir }
);

has [ qw(matlab_function c_function) ] => ( is => 'ro', required => 1 );

has qw(function_states) => ( is => 'lazy', clearer => 1 );

sub _build_function_states {
	my ($self) = @_;
	my $m_name = $self->matlab_function->name;

	my $mat_file_rule = Path::Iterator::Rule->new
		->file->name( qr/\Q$m_name\E\.F_BEGIN.*\.mat$/ );
	my $mat_file_iter = $mat_file_rule->iter( $self->function_state_dir );

	my @f_states;
	while( defined( my $mat_file = $mat_file_iter->() ) ) {
		my $f = ORION::FunctionStateFile->new_from_from_filename($mat_file);
		push @f_states, $f;
	}

	\@f_states;
}

sub compare_state {
	my ($self, $fs) = @_;

	my $m = $self->matlab_function;
	my $c = $self->c_function;

	my $mapping = $ORION::FunctionCompareData::MAPPING->{$m->name};
	my %map_c_to_m = reverse %{ $mapping->{param_map} };
	my $c_params = $c->params;
	my $m_params_by_name = { map { $_->name => $_ } @{ $m->params } };

	# list of MATLAB input parameters that match the order of the C input parameters
	my @ordinal_map_m_to_c = ();

	my $m_param_done = {};
	my $add_matlab_param = sub  {
		my ($m_param_name) = @_;
		if( exists $m_param_done->{$m_param_name} ) {
			die "Param $m_param_name already exists in M->C parameter mapping: @ordinal_map_m_to_c";
		}
		push @ordinal_map_m_to_c, $m_param_name;
		$m_param_done->{$m_param_name} = 1;
	};


	for my $c_param (@$c_params) {
		if( exists $map_c_to_m{$c_param->name} ) {
			# look up mapping of C parameter name to MATLAB
			# parameter name
			$add_matlab_param->( $map_c_to_m{$c_param->name} );
		} elsif( exists $m_params_by_name->{$c_param->name} ) {
			# if the MATLAB parameters have the same name as the C parameter
			$add_matlab_param->( $m_params_by_name->{$c_param->name}->name );
		} else {
			die "Could not find match for C parameter @{[ $c_param->name ]} for C function @{[ $c->name ]}: "
		}
	}

	my $matlab_input_values = $fs->input;
	my $matlab_output_values = $fs->output;

	my $c_input_values = [
		map {
			ORION::Types->coerce_type(
				$c_params->[$_]->type,
				$matlab_input_values->{$ordinal_map_m_to_c[$_]})
		} 0..@$c_params-1 ];

	#use DDP; p $m->params;
	#use DDP; p $c->params;
	#use DDP; p @ordinal_map_m_to_c;
	#use DDP; p $c_input_values;

	my $expected_c_output;
	if( scalar keys %$matlab_output_values ) {
		my ($output_name) = keys %$matlab_output_values;
		$expected_c_output = $matlab_output_values->{$output_name};
		use DDP; p $expected_c_output;
	} else {
		LOGDIE("Do not know which outputs to compare for "
			."MATLAB function @{[ $m->name ]}: "
			."@{[ keys %$matlab_output_values ]}");
	}
	my $got_c_output;

	{
		no strict 'refs';
		my $c_func_name = $c->name;
		my $c_func_perl = "ORION::$c_func_name";
		if( defined &$c_func_perl ) {
			$got_c_output = &$c_func_perl( @$c_input_values );
		} else {
			LOGWARN("The C function $c_func_name was not bound to Perl at $c_func_perl");
			return;
		}
	}

	my $compare = $mapping->{compare} // \&ORION::Compare::compare_volume_inf_norm;

	my $diff = $compare->( expected => $expected_c_output, got => $got_c_output);

	$diff;
}

1;

package ORION::FunctionCompare;

use Moo;

use ORION::FunctionStateFile;
use ORION::Types;

has qw(function_state_dir) => ( is => 'ro', required => 1,
	default => sub {
		my $debug_trace_dir = ORION->datadir->child(qw(debug-trace));
	}
);

has [ qw(matlab_function c_function) ] => ( is => 'ro', required => 1 );

has qw(function_states) => ( is => 'lazy' );

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

	my $matlab_param = [ map { $_->name } @{ $m->params } ];
	my $c_param = [ map { $_->name } @{ $c->params } ];
	my $c_param_type = [ map { $_->type } @{ $c->params } ];
	my $matlab_input_values = $fs->input;
	my $matlab_output_values = $fs->output;

	my $c_input_values = [
		map {
			ORION::Types->coerce_type(
				$c_param_type->[$_],
				$matlab_input_values->{$matlab_param->[$_]})
		} 0..@$matlab_param-1 ];

	my $expected_c_output = $matlab_output_values->{val};

	my $got_c_output = ORION::orion_hdaf( @$c_input_values );

	my $diff = abs($expected_c_output - $got_c_output);
	use DDP; p $diff->max;
}

1;

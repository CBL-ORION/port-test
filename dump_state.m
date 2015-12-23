% This function can only be used when in debug mode.
function dump_state()
	call_stack = dbstack('-completenames', 1);
	assert( ~isempty( call_stack ),...
		'Non-empty call stack. Called from outside debugger.');

	%% Identify stopping location
	% 1. function start
	% 2. function end
	% 3. I/O-related

	%% Determine names of input and output variables.
	[input_args, output_args] = get_arg_names(call_stack(1).name);

	input_args
	output_args


end

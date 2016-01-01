function caller_state = dump_state(path_to_output_directory)
% function dump_state()
%
% Dumps the state of the current function.
%
% Note:
%  - This function can only be used when in debug mode.

	% where the output will be stored
	caller_state = struct();
	caller_state.TIME = cputime;

	%% Get current function name
	call_stack = dbstack('-completenames', 1);
	assert( ~isempty( call_stack ),...
		'Empty call stack. Called from outside debugger.');

	% current_func is a struct with the fields
	%  * .name : function name
	%  * .file : full path to the file
	%  * .line : line where stopped
	current_func = call_stack(1);

	% Get breakpoints for current file
	current_file_bps = dbstatus( current_func.file );
	bps_idx_for_current_function =  find(ismember( { current_file_bps.name }, current_func.name ));
	current_file_bps = current_file_bps(bps_idx_for_current_function);

	bp_for_current_line = find(current_file_bps.line == current_func.line);
	if numel( bp_for_current_line ) ~= 1
		error( 'Found %d breakpoints for %s:%d when expecting 1',...
				numel( break_point_for_current_line ),...
				current_func.file,...
				current_func.line );
	end

	caller_state.NAME = current_func.name;
	caller_state.LINE = current_func.line;

	%% Identify stopping location
	% 1. function start
	% 2. function end
	% 3. I/O-related

	% bp_expr_for_current_line is the expression for conditionally
	% breaking at the given breakpoint
	bp_expr_for_current_line = current_file_bps.expression{bp_for_current_line};
	if regexp(bp_expr_for_current_line, '^tracer\(\s*''F'',\s*''begin''\s*\)$')
		caller_state.WHERE = 'F_BEGIN';
	elseif regexp(bp_expr_for_current_line, '^tracer\(\s*''F'',\s*''end''\s*\)$')
		caller_state.WHERE = 'F_END';
	end

	%% Determine names of input and output variables.
	[input_args, output_args] = get_arg_names(current_func.name);

	%% Store the input or output variables into the `caller_state`.
	% NOTE: the loops below can not be moved to their own functions because
	% that will add another function to the call stack and then
	% evalin('caller', ...) will no longer work.
	if strcmp( caller_state.WHERE, 'F_BEGIN' )
		caller_state.input = struct();
		for input_args_i = 1:length(input_args)
			cur_input_arg = input_args{input_args_i};
			caller_state.input = setfield(...
				caller_state.input,...
				cur_input_arg,...
				evalin( 'caller', cur_input_arg )...
			);
		end
	elseif strcmp( caller_state.WHERE, 'F_END' )
		caller_state.output = struct();
		for output_args_i = 1:length(output_args)
			cur_output_arg = output_args{output_args_i};
			caller_state.output = setfield(...
				caller_state.output,...
				cur_output_arg,...
				evalin( 'caller', cur_output_arg )...
			);
		end
	end

	%% Save to unique file
	fname = tempname;
	[~,fname] = fileparts(fname);
	full_fname = fullfile( path_to_output_directory, [ fname '.mat' ] );

	save( [full_fname '.v7'  ], 'caller_state', '-v7' );   % Matlab-specific
end

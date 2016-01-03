function caller_state = dump_state(path_to_output_directory)
% function dump_state()
%
% Dumps the state of the current function.
%
% Note:
%  - This function can only be used when in debug mode.
	persistent otrace_stack;
	if isempty(otrace_stack)
		% empty struct at start
		otrace_stack = struct('name', {}, 'id', {});
	end

	% where the output for this particular function will be stored
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
	current_file_bps = dbstatus('-completenames', current_func.file );
	% need to get only the function name
	% e.g, not '/path/to/function.m>subfunction'
	bps_short_names = regexprep( { current_file_bps.name }, '^.*>(?<fname>[^>]*)$', '$<fname>' );
	bps_idx_for_current_function =  find(ismember( bps_short_names, current_func.name ));
	current_file_bps = current_file_bps(bps_idx_for_current_function);

	bp_for_current_line = find(current_file_bps.line == current_func.line);
	if numel( bp_for_current_line ) ~= 1
		error( 'Found %d breakpoints for %s:%d when expecting 1',...
				numel( break_point_for_current_line ),...
				current_func.file,...
				current_func.line );
	end

	caller_state.NAME = current_func.name;
	caller_state.FILE = current_func.file;
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
		%% Stack info
		caller_state.STACKID = gen_guid()

		current_stack_info = struct(...
			'name', caller_state.NAME,...
			'id', caller_state.STACKID);

		% push current state on to stack
		otrace_stack = [ otrace_stack, current_stack_info ];
		caller_state.STACK = otrace_stack;

		caller_state.input = struct();
		input_args
		for input_args_i = 1:length(input_args)
			cur_input_arg = input_args{input_args_i};
			try
				% try-catch in case the input variable is optionally set
				caller_state.input = setfield(...
					caller_state.input,...
					cur_input_arg,...
					evalin( 'caller', cur_input_arg )...
				);
			catch ME
				ME
				disp(sprintf('Could not find input variable "%s" in caller', cur_input_arg));
			end
		end
	elseif strcmp( caller_state.WHERE, 'F_END' )
		%% Stack info

		% the last item on the stack contains the stack ID
		caller_state.STACKID = otrace_stack(end).id;
		caller_state.STACK = otrace_stack;

		
		if( ~ strcmp( otrace_stack(end).name, caller_state.NAME ) )
			error( 'Stack seems malformed. The last item in the stack (%s) does not have the same name as the current function (%s).',...
				otrace_stack(end).name, caller_state.NAME );
			otrace_stack_cell = struct2cell(otrace_stack);
			otrace_stack_cell
		end

		otrace_stack = otrace_stack(1:end-1); % pop off stack


		caller_state.output = struct();
		for output_args_i = 1:length(output_args)
			cur_output_arg = output_args{output_args_i};
			try
				% try-catch in case the output variable is optionally set
				caller_state.output = setfield(...
					caller_state.output,...
					cur_output_arg,...
					evalin( 'caller', cur_output_arg )...
				);
			catch
				ME
				disp(sprintf('Could not find output variable "%s" in caller', cur_output_arg));
			end
		end
	end
	struct2cell(otrace_stack)

	%% Save to unique file
	% TODO give filename based on function name and stack ID
	fname = sprintf('%s.%s.%s.mat',...
		caller_state.NAME,...
		caller_state.WHERE,...
		caller_state.STACKID);
	full_fname = fullfile( path_to_output_directory, fname );

	save( full_fname, 'caller_state', '-v7' );   % Matlab-specific
end

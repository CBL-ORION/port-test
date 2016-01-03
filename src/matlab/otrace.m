function otrace(path_to_project, code_to_eval, skip_func)
	%% Add the top level of the path to the MATLAB path.
	addpath(genpath(path_to_project));
	[path_to_current_mat,~,~] = fileparts(mfilename('fullpath'));
	addpath(genpath(path_to_current_mat));

	m_funcs = get_project_matlab_funcs(path_to_project);
	if exist('skip_func', 'var')
		% remove all instances that need to be skipped
		m_funcs = m_funcs( find( ~ ismember( m_funcs, skip_func ) ) );
	end

	%% Set up tracer for debugging
	log = TraceHistory.Instance;
	for m_funcs_i = 1:size( m_funcs, 1 )
		% This needs to be run one at a time otherwise dbstatus
		% complains about too many input arguments.

		m_func_current = m_funcs{m_funcs_i,1};

		% get the number of files in the path with the same name
		filespec = which( m_func_current, '-all' );
		if numel( filespec ) == 1
			% only add to debugging if there is a single instance
			log.setup( { m_func_current } );
		else
			warning('Function %s has %d files with the same name in the path.',...
				m_func_current, numel( filespec ));
		end
	end

	%% Run the code.
	eval(code_to_eval);
end
